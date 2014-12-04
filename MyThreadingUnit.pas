unit MyThreadingUnit;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections, System.SyncObjs;

type
  TMyThread1 = class( TThread )
  protected
    FProc : TProc;
    FInterval:Integer;
  public
    procedure Execute(); override;

    procedure Synchronize(AThreadProc: TThreadProcedure); overload; inline;

  public
		constructor Create(AInterval: Integer; AProc: TProc);

  end;
//---------------------------------------------------------------------------
  TMyThread2 = class( TThread )
  protected
    FProcList   : TList<TProc>;
    FSection    : TCriticalSection;
    FWakeEvent  : TEvent;

  public
    procedure Execute(); override;

    procedure Synchronize(AThreadProc: TThreadProcedure); overload; inline;

  public
    procedure ExecuteProc( AProc : TProc );

  public
    constructor Create();
    destructor  Destroy(); override;

  end;
//---------------------------------------------------------------------------
  TMyExecution = class
    type
      TMyThread = class( TThread )
      protected
        FProc : TProc;
        FSyncProc: TThreadProcedure;
      public
        procedure Execute(); override;

      public
				constructor Create(AProc: TProc; AThreadProc: TThreadProcedure = nil);
      end;

  protected
    FThreadList : TObjectList<TMyThread>;

  public
		procedure ExecuteProc(AProc: TProc; AThreadProc: TThreadProcedure = nil);
    procedure WaitFor();

  public
    constructor Create();
    destructor  Destroy(); override;

  end;
//---------------------------------------------------------------------------
  TDelegate = class
  public
    class function Capture<T>( AItem : T; AProc : TProc<T> ) : TProc; inline;

  end;
//---------------------------------------------------------------------------
implementation


//---------------------------------------------------------------------------
constructor TMyThread1.Create(AInterval: Integer; AProc: TProc);
begin
  inherited Create();
  FInterval:=AInterval;
  FProc := AProc;
end;
//---------------------------------------------------------------------------
procedure TMyThread1.Execute();
begin
  while( not Terminated ) do
  begin
    FProc();
    Sleep(FInterval * 1000);
  end;
end;
//---------------------------------------------------------------------------
procedure TMyThread1.Synchronize(AThreadProc: TThreadProcedure);
begin
  inherited Synchronize( AThreadProc );
end;
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
constructor TMyThread2.Create();
begin
  inherited; // Create(True);
  FProcList := TList<TProc>.Create();
  FSection := TCriticalSection.Create();
  FWakeEvent := TEvent.Create();
end;
//---------------------------------------------------------------------------
destructor TMyThread2.Destroy();
begin
  Terminate();
  FWakeEvent.SetEvent();
  WaitFor();

  FSection.Free();
  FWakeEvent.Free();
  FProcList.Free();
  inherited;
end;
//---------------------------------------------------------------------------
procedure TMyThread2.Execute();
var
  AProc : TProc;

begin
  while( not Terminated ) do
    begin
    FSection.Enter();
    try
      if( FProcList.Count = 0 ) then
        AProc := NIL

      else
        begin
        AProc := FProcList.First();
        FProcList.Delete( 0 );
        end;

    finally
      FSection.Leave();
    end;

    if( Assigned( AProc )) then
      AProc()
     else
      FWakeEvent.WaitFor();
    end;
end;
//---------------------------------------------------------------------------
procedure TMyThread2.Synchronize(AThreadProc: TThreadProcedure);
begin
  inherited Synchronize( AThreadProc );
end;
//---------------------------------------------------------------------------
procedure TMyThread2.ExecuteProc( AProc : TProc );
begin
  FSection.Enter();
  try
    FProcList.Add( AProc );
  finally
    FSection.Leave();
  end;

  FWakeEvent.SetEvent();
end;
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
constructor TMyExecution.Create();
begin
  inherited;
  FThreadList := TObjectList<TMyThread>.Create();
end;
//---------------------------------------------------------------------------
destructor TMyExecution.Destroy();
begin
  FThreadList.Free();
  inherited;
end;
//---------------------------------------------------------------------------
procedure TMyExecution.ExecuteProc(AProc: TProc; AThreadProc: TThreadProcedure
		= nil);
 var T:TMyThread;
begin
  T:=TMyThread.Create(AProc, AThreadProc);

  FThreadList.Add( T );
end;
//---------------------------------------------------------------------------
procedure TMyExecution.WaitFor();
var
  AItem : TMyThread;

begin
  for AItem in FThreadList do
    AItem.WaitFor();
end;
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
constructor TMyExecution.TMyThread.Create(AProc: TProc; AThreadProc:
		TThreadProcedure = nil);
begin
  inherited Create();
  FProc := AProc;
  FSyncProc:=AThreadProc;
end;
//---------------------------------------------------------------------------
procedure TMyExecution.TMyThread.Execute();
begin
  FProc();
  if Assigned(FSyncProc) then Synchronize(FSyncProc);
end;

//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
class function TDelegate.Capture<T>( AItem : T; AProc : TProc<T> ) : TProc;
begin
  Result := procedure()
            begin
              AProc( AItem );
            end;

end;
//---------------------------------------------------------------------------
end.
