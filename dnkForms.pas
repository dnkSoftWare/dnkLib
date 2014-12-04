unit dnkForms;

interface

uses
  Vcl.Forms, System.Classes, System.Types, Vcl.StdCtrls, Vcl.ExtCtrls, Controls, SysUtils, Vcl.Graphics
  //,UnitWaitForm
  ;

type
  TMessageFormPosition = (mfpoScreenCenter, mfpoWinOwnerCenter, mfpoWinOwnerTopLeft, mfpoWinOwnerTopRight,
   mfpoWinOwnerBottomLeft, mfpoWinOwnerBottomRight);
//  TInterfacedForm = class(TInterfacedObject, IInterface);

  IMessageForm = interface
  end;

  TMessageForm = class(TInterfacedObject, IMessageForm) // авто уничтожающийся мессаг с таймером внутри
  private
   FForm:TForm;
   FTimer:TTimer;

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

  end;



implementation

destructor TMessageForm.Destroy;
begin
 FTimer.Free;
 if Assigned(FForm) { and (not FForm.FTimer.Enabled) } then
  begin
   FreeAndNil(FForm);
  end;
 // inherited;
end;

constructor TMessageForm.Create(AOwner: TComponent; ACaption, AText: string;
    const AHideAfteMilliSeconds: Integer = 0; const Position:
    TMessageFormPosition = mfpoScreenCenter; const AColor: TColor = clYellow);
 var
  P: TLabel;
  R: TRect;
begin
  if AOwner = nil then
  FForm := TForm.Create(Screen)
   else
  FForm := TForm.Create(AOwner);

  FForm.Parent:=nil; // TWinControl(Screen);

  FForm.Caption:=Application.Title + ' - ' + ACaption;

  FTimer:=TTimer.Create(nil);

  FTimer.OnTimer:=DestroyForm;

  if AHideAfteMilliSeconds>0 then
   begin
    FTimer.Interval:=AHideAfteMilliSeconds;
   end;

  case Position of
   mfpoScreenCenter:FForm.Position:=poScreenCenter;
  end;

  FForm.FormStyle:=fsStayOnTop;
  FForm.BorderStyle:=bsToolWindow;
  P:=TLabel.Create(FForm);
  with P do
    begin
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
   mfpoScreenCenter:FForm.Position:=poScreenCenter;
   mfpoWinOwnerTopLeft:begin FForm.Top:= TForm(AOwner).Top+(TForm(AOwner).Height - TForm(AOwner).ClientHeight);
      FForm.Left:= TForm(AOwner).Left+15;   end;
   mfpoWinOwnerTopRight:begin FForm.Top:= TForm(AOwner).Top+(TForm(AOwner).Height - TForm(AOwner).ClientHeight);
      FForm.Left:= (TForm(AOwner).Left+TForm(AOwner).ClientWidth-FForm.Width)-5;   end;
   mfpoWinOwnerBottomLeft:begin FForm.Top:= TForm(AOwner).Top + TForm(AOwner).ClientHeight - FForm.Height;
      FForm.Left:= TForm(AOwner).Left+15;   end;
   mfpoWinOwnerBottomRight:begin FForm.Top:= TForm(AOwner).Top + TForm(AOwner).ClientHeight - FForm.Height;
      FForm.Left:= (TForm(AOwner).Left+TForm(AOwner).ClientWidth-FForm.Width)-5;   end;

   mfpoWinOwnerCenter:begin
      FForm.Position:=poOwnerFormCenter;
    end;

  end;


  FTimer.Enabled:=True;
  FForm.Show;
  Application.ProcessMessages; // даём отрисоваться...
end;

procedure TMessageForm.DestroyForm(Sender: TObject);
begin
  FTimer.Enabled:=False;
  FreeAndNil( FForm );
end;

end.
