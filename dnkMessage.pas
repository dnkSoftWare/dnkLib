unit dnkMessage;

interface

uses
  Vcl.Forms, System.Classes, System.Types, Vcl.StdCtrls, Vcl.ExtCtrls, Controls, SysUtils, Vcl.Graphics,
  uFormBase;

type
  TMessageFormPosition = (mfpoScreenCenter, mfpoWinOwnerCenter, mfpoWinOwnerTopLeft, mfpoWinOwnerTopRight,
   mfpoWinOwnerBottomLeft, mfpoWinOwnerBottomRight);
//  TInterfacedForm = class(TInterfacedObject, IInterface);

	IMessageForm = interface(IInterface)
	['{370E54C7-A200-4FFF-8FD9-C7C833A878C6}']
		procedure ReShow(ANewCaption, ANewText: string; AAddSeconds: Integer = 0);
    procedure Close;
  end;

  TMessageForm = class(TInterfacedObject, IMessageForm) // авто уничтожающийся мессаг с таймером внутри
  private
   FForm:TFormBase;
   FTimer:TTimer;
   FCopyObj:IMessageForm;
  public
   destructor Destroy; override;

   ///	<summary>
   ///	  Создаёт и отображает мессагу
   ///	</summary>
   ///	<param name="ACaption">
   ///	  Заголовок
   ///	</param>
   ///	<param name="AText">
   ///	  Текст
   ///	</param>
   ///	<param name="AHideAfteMilliSeconds">
   ///	  Скрывать после задержки
   ///	</param>
   ///	<param name="Position">
   ///	  Положение
   ///  mfpoScreenCenter, mfpoWinOwnerCenter, mfpoWinOwnerTopLeft, mfpoWinOwnerTopRight, mfpoWinOwnerBottomLeft, mfpoWinOwnerBottomRight
   ///	</param>
   ///	<param name="AColor">
   ///	  Цвет фона
   ///	</param>
   constructor Create(AOwner: TComponent; ACaption, AText: string; const
       AHideAfteMilliSeconds: Integer = 0; const Position: TMessageFormPosition =
       mfpoScreenCenter; const AColor: TColor = clYellow); overload;
   procedure DestroyForm(Sender: TObject);
   procedure Close;
	 procedure ReShow(ANewCaption, ANewText: string; AAddSeconds: Integer = 0);
  end;


var
 GlobalTopPos:Integer;   // Смещение для нового окна по вертикали

function CreateMessage(AOwner: TComponent; ACaption, AText: string; const
       AHideAfteMilliSeconds: Integer = 0; const Position: TMessageFormPosition =
       mfpoScreenCenter; const AColor: TColor = clYellow): IMessageForm;

implementation

function CreateMessage(AOwner: TComponent; ACaption, AText: string; const
       AHideAfteMilliSeconds: Integer = 0; const Position: TMessageFormPosition =
       mfpoScreenCenter; const AColor: TColor = clYellow): IMessageForm;
begin
 Result:=TMessageForm.Create(AOwner, ACaption, AText, AHideAfteMilliSeconds, Position, AColor );
end;

destructor TMessageForm.Destroy;
begin
 if Assigned(FTimer) then FreeAndNil( FTimer );
 GlobalTopPos:= GlobalTopPos - FForm.Height - 5;
 FreeAndNil( FForm );
end;

constructor TMessageForm.Create(AOwner: TComponent; ACaption, AText: string;
    const AHideAfteMilliSeconds: Integer = 0; const Position:
    TMessageFormPosition = mfpoScreenCenter; const AColor: TColor = clYellow);
 var
  P: TLabel;
  R: TRect;
begin
  if AOwner = nil then
  FForm := TFormBase.Create(Screen)
   else
  FForm := TFormBase.Create(AOwner);

  FForm.Parent:=nil;

  FForm.Caption:=Application.Title + ' - ' + ACaption;

  if AHideAfteMilliSeconds>0 then
   begin
    FTimer:=TTimer.Create(nil);
    FTimer.OnTimer:=DestroyForm;
    FTimer.Interval:=AHideAfteMilliSeconds;
   end;

//  case Position of
//   mfpoScreenCenter:FForm.Position:=poScreenCenter;
//  end;

  FForm.FormStyle:=fsNormal;
  FForm.BorderStyle:=bsToolWindow;
  P:=TLabel.Create(FForm);
  with P do
    begin
      Name                          :='TextLabel';
      Parent                        :=FForm;
      ParentColor                   :=False;
      ParentFont                    :=False;
      Align                         :=alClient;
      Alignment                     :=taCenter;
      Layout                        :=tlCenter;
      Caption                       :=AText;
      Font.Size                     :=14;
      Transparent                   :=False;
      Color                         :=AColor;
      AutoSize                      :=True;
    end;

   FForm.Width:=FForm.Canvas.TextWidth(P.Caption) * 2;
   FForm.Height:=FForm.Canvas.TextHeight(P.Caption) * 4;

  case Position of
   mfpoScreenCenter: begin
                      // FForm.Position:=poScreenCenter;
                       FForm.Top:= (Screen.Height div 2) - (FForm.Height div 2);
                       FForm.Left:= (Screen.Width div 2) - (FForm.Width div 2);
                     end;
   mfpoWinOwnerTopLeft:begin FForm.Top:= TForm(AOwner).Top+(TForm(AOwner).Height - TForm(AOwner).ClientHeight);
      FForm.Left:= TForm(AOwner).Left+15;  end;
   mfpoWinOwnerTopRight:begin FForm.Top:= TForm(AOwner).Top+(TForm(AOwner).Height - TForm(AOwner).ClientHeight);
      FForm.Left:= (TForm(AOwner).Left+TForm(AOwner).ClientWidth-FForm.Width)-5;  end;
   mfpoWinOwnerBottomLeft:begin FForm.Top:= TForm(AOwner).Top + TForm(AOwner).ClientHeight - FForm.Height;
      FForm.Left:= TForm(AOwner).Left+15;  end;
   mfpoWinOwnerBottomRight:begin FForm.Top:= TForm(AOwner).Top + TForm(AOwner).ClientHeight - FForm.Height;
      FForm.Left:= (TForm(AOwner).Left+TForm(AOwner).ClientWidth-FForm.Width)-5;  end;
   mfpoWinOwnerCenter:begin
                        // FForm.Position:=poOwnerFormCenter;
                        if Assigned(AOwner) then
                           begin
                             FForm.Top:= (TForm(AOwner).Height div 2) - (TForm(FForm).Height div 2);
                             FForm.Left:= (TForm(AOwner).Width div 2) - (TForm(FForm).Width div 2);
                           end;
                      end;
  end;

  FForm.Top:=FForm.Top + GlobalTopPos; GlobalTopPos:= GlobalTopPos + FForm.Height + 5;


  if Assigned(FTimer) then
   begin
     FCopyObj:=Self as IMessageForm;
     FTimer.Enabled:=True;
   end;
  FForm.Show;
  Application.ProcessMessages; // даём отрисоваться...
end;

procedure TMessageForm.DestroyForm(Sender: TObject);
begin
  FForm.Close;
  if Assigned(FTimer) then FTimer.Enabled:=False;
  FCopyObj:=nil;
end;

procedure TMessageForm.Close;
begin
  FForm.Close;
end;

procedure TMessageForm.ReShow(ANewCaption, ANewText: string; AAddSeconds:
		Integer = 0);
var
  I: Integer;
begin
  if Assigned(fTimer) and FTimer.Enabled then begin
                                                FTimer.Enabled:=False;
                                                FTimer.Interval:=FTimer.Interval + (1000 * AAddSeconds);
                                              end;

  FForm.Hide;
  Application.ProcessMessages; // даём отрисоваться...
  FForm.Caption:=ANewCaption;
  If FForm.FindChildControl('TextLabel') is TLabel then
   (FForm.FindChildControl('TextLabel') as TLabel).Caption:=ANewText;
  FForm.Repaint;
  Application.ProcessMessages; // даём отрисоваться...

  if Assigned(fTimer) then FTimer.Enabled:=True;
end;

initialization
 GlobalTopPos:=0; // По умолчанию смещения нет!

end.
