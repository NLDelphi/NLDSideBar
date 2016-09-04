{ *************************************************************************** }
{                                                                             }
{ NLDSideBar  -  www.nldelphi.com Open Source Delphi designtime component     }
{                                                                             }
{ Initiator: Albert de Weerd (aka NGLN)                                       }
{ License: Free to use, free to modify                                        }
{ SVN path: http://svn.nldelphi.com/nldelphi/opensource/ngln/NLDSideBar       }
{                                                                             }
{ *************************************************************************** }
{                                                                             }
{ Date: December 8, 2010                                                      }
{ Version: 1.0.0.1                                                            }
{                                                                             }
{ *************************************************************************** }

unit NLDSideBar;

interface

uses
  Controls, Classes, StdCtrls, Themes, Windows, Graphics, Messages, Buttons,
  Forms, ExtCtrls, Math, Types;

const
  DefSideButtonWidth = 25;
  DefWidth = 130;

type
  TSideBarAlign = alLeft..alRight;

  TNLDSideButton = class(TCustomControl)
  private
    FActivated: Boolean;
    FMouseOver: Boolean;
    FOnMouseEnter: TNotifyEvent;
    FOnMouseLeave: TNotifyEvent;
    procedure CMDialogChar(var Message: TCMDialogChar); message CM_DIALOGCHAR;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
  protected
    procedure Paint; override;
    procedure RequestAlign; override;
  public
    procedure Activate;
    constructor Create(AOwner: TComponent); override;
    procedure Deactivate;
    property OnMouseEnter: TNotifyEvent read FOnMouseEnter write FOnMouseEnter;
    property OnMouseLeave: TNotifyEvent read FOnMouseLeave write FOnMouseLeave;
  public
    property OnClick;
  end;

  THoverPosition = (hpLeft, hpMiddle, hpRight);
  TSizingEdge = (seNone, seLeft, seRight);

  TNLDSideBar = class(TCustomControl)
  private
    FAlign: TSideBarAlign;
    FAutoHide: Boolean;
    FMouseOver: Boolean;
    FOnAutoHideChanged: TNotifyEvent;
    FOnHide: TNotifyEvent;
    FPinButton: TSpeedButton;
    FPinButtonDownHint: String;
    FPinButtonUpHint: String;
    FResizable: Boolean;
    FSideButton: TNLDSideButton;
    FStreamedAutoHide: Boolean;
    FMinWidth: Integer;
    procedure AutoHideChanged;
    procedure Delayed;
    function GetAutoHide: Boolean;
    function GetHint: String;
    function GetHoverPosition(X: Integer): THoverPosition;
    function GetPinButtonVisible: Boolean;
    function GetSideButtonWidth: Integer;
    procedure PinButtonClicked(Sender: TObject);
    procedure SetAlign(Value: TSideBarAlign);
    procedure SetAutoHide(Value: Boolean);
    procedure SetHint(const Value: String);
    procedure SetMinWidth(const Value: Integer);
    procedure SetSideButtonWidth(Value: Integer);
    procedure SetPinButtonDownHint(const Value: String);
    procedure SetPinButtonUpHint(const Value: String);
    procedure SetPinButtonVisible(Value: Boolean);
    procedure SetResizable(Value: Boolean);
    procedure SideButtonClicked(Sender: TObject);
    procedure SideButtonMouseEntered(Sender: TObject);
    procedure SideButtonMouseLeft(Sender: TObject);
    procedure SideButtonResized(Sender: TObject);
    procedure UpdateDocking;
    procedure UpdatePinButtonHint;
    procedure UpdatePlacement;
    procedure CMEnabledChanged(var Message: TMessage);
      message CM_ENABLEDCHANGED;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMParentFontChanged(var Message: TMessage);
      message CM_PARENTFONTCHANGED;
    procedure CMShowHintChanged(var Message: TMessage);
      message CM_SHOWHINTCHANGED;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
  protected
    procedure AdjustClientRect(var Rect: TRect); override;
    function CanResize(var NewWidth, NewHeight: Integer): Boolean; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X,
      Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X,
      Y: Integer); override;
    procedure Paint; override;
    procedure SetParent(AParent: TWinControl); override;
    procedure WndProc(var Message: TMessage); override;
  public
    function CanFocus: Boolean; override;
    constructor Create(AOwner: TComponent); override;
    procedure Hide;
  published
    property Align: TSideBarAlign read FAlign write SetAlign default alLeft;
    property AutoHide: Boolean read GetAutoHide write SetAutoHide default False;
    property Hint: String read GetHint write SetHint;
    property MinWidth: Integer read FMinWidth write SetMinWidth
      default DefWidth;
    property OnAutoHideChanged: TNotifyEvent read FOnAutoHideChanged
      write FOnAutoHideChanged;
    property OnHide: TNotifyEvent read FOnHide write FOnHide;
    property PinButtonDownHint: String read FPinButtonDownHint
      write SetPinButtonDownHint;
    property PinButtonUpHint: String read FPinButtonUpHint
      write SetPinButtonUpHint;
    property PinButtonVisible: Boolean read GetPinButtonVisible
      write SetPinButtonVisible default True;
    property Resizable: Boolean read FResizable write SetResizable default True;
    property SideButtonWidth: Integer read GetSideButtonWidth
      write SetSideButtonWidth default DefSideButtonWidth;
  published
    property Caption;
    property Color default clBtnFace;
    property Font;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property TabOrder;
    property TabStop;
  end;

implementation

{$R NLDSideBar.dcr}

resourcestring
  SPinButtonBmpResName = 'PINBUTTON';

procedure RotateDC90(Source, Dest: HDC; Width, Height: Integer);
var
  Points: array[0..2] of TPoint;
begin
  Points[0].X := 0;
  Points[0].Y := Width;
  Points[1].X := 0;
  Points[1].Y := 0;
  Points[2].X := Height;
  Points[2].Y := Width;
  PlgBlt(Dest, Points, Source, 0, 0, Width, Height, 0, 0, 0);
end;

{ TNLDSideButton }

procedure TNLDSideButton.Activate;
begin
  if not FActivated then
  begin
    FActivated := True;
    Invalidate;
  end;
end;

procedure TNLDSideButton.CMDialogChar(var Message: TCMDialogChar);
begin
  if IsAccel(Message.CharCode, Caption) and Enabled and Visible and
    (Parent <> nil) and Parent.Showing then
  begin
    Click;
    Message.Result := 1;
  end
  else
    inherited;
end;

procedure TNLDSideButton.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  if Enabled and not FMouseOver then
  begin
    FMouseOver := True;
    Invalidate;
    if Assigned(FOnMouseEnter) then
      FOnMouseEnter(Self);
  end;
end;

procedure TNLDSideButton.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FMouseOver then
  begin
    FMouseOver := False;
    Invalidate;
    if Assigned(FOnMouseLeave) then
      FOnMouseLeave(Self);
  end;
end;

procedure TNLDSideButton.CMTextChanged(var Message: TMessage);
begin
  Invalidate;
end;

constructor TNLDSideButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Color := clBtnFace;
  ControlStyle := [csClickEvents, csOpaque, csNoDesignVisible];
  SetBounds(0, 0, DefSideButtonWidth, 300);
  DoubleBuffered := True;
end;

procedure TNLDSideButton.Deactivate;
begin
  if FActivated then
  begin
    FActivated := False;
    Invalidate;
  end;
end;

procedure TNLDSideButton.Paint;
const
  LogFontAngles: array[Boolean] of Longint = (900, 2700);
var
  R: TRect;
  Button: TThemedButton;
  Details: TThemedElementDetails;
  DrawFlags: Integer;
  LogFont: TLogFont;
  OldFont: HFONT;
  NewFont: HFONT;
  TextSize: TSize;
  Bmp: TBitmap;
begin
  R := Rect(0, 0, Width, Height);
  if ThemeServices.ThemesEnabled then
  begin
    PerformEraseBackground(Self, Canvas.Handle);
    if not Enabled then
      Button := tbPushButtonDisabled
    else if FActivated then
      Button := tbPushButtonPressed
    else if FMouseOver then
      Button := tbPushButtonHot
    else
      Button := tbPushButtonNormal;
    Details := ThemeServices.GetElementDetails(Button);
    Bmp := TBitmap.Create;
    try
      Bmp.Width := Height;
      Bmp.Height := Width;
      ThemeServices.DrawElement(Bmp.Canvas.Handle, Details,
        Rect(0, 0, Height, Width));
      RotateDC90(Bmp.Canvas.Handle, Canvas.Handle, Height, Width);
    finally
      Bmp.Free;
    end;
  end
  else
  begin
    DrawFlags := DFCS_BUTTONPUSH or DFCS_ADJUSTRECT;
    if FActivated then
      DrawFlags := DrawFlags or DFCS_PUSHED;
    DrawFrameControl(Canvas.Handle, R, DFC_BUTTON, DrawFlags);
    if FMouseOver and not FActivated then
    begin
      Canvas.Brush.Bitmap := AllocPatternBitmap(clBtnFace, clBtnHighlight);
      Canvas.FillRect(R);
    end;
  end;
  Canvas.Brush.Style := bsClear;
  Canvas.Font := Font;
  if not Enabled then
    Canvas.Font.Color := clGrayText;
  GetObject(Canvas.Font.Handle, SizeOf(LogFont), @LogFont);
  LogFont.lfEscapement := LogFontAngles[Align = alRight];
  LogFont.lfOrientation := LogFontAngles[Align = alRight];
  LogFont.lfOutPrecision := OUT_TT_ONLY_PRECIS;
  NewFont := CreateFontIndirect(LogFont);
  OldFont := SelectObject(Canvas.Handle, NewFont);
  TextSize := Canvas.TextExtent(Caption);
  with CenterPoint(R) do
    if Align = alLeft then
      Canvas.TextRect(R, X - TextSize.cy div 2, Y + TextSize.cx div 2, Caption)
    else
      Canvas.TextRect(R, X + TextSize.cy div 2, Y - TextSize.cx div 2, Caption);
  NewFont := SelectObject(Canvas.Handle, OldFont);
  DeleteObject(NewFont);
end;

procedure TNLDSideButton.RequestAlign;
begin
  inherited RequestAlign;
  Invalidate;
end;

procedure TNLDSideButton.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

{ TNLDSideBar }

const
  DefMargin = 4;
  DefPinButtonSize = 20;
  DefTimerInterval = 400;
  EdgeSize = 4;

var
  OldLeft: Integer;
  OldWidth: Integer;
  OldX: Integer;
  SizingEdge: TSizingEdge = seNone;

procedure TNLDSideBar.AdjustClientRect(var Rect: TRect);
begin
  inherited AdjustClientRect(Rect);
  Inc(Rect.Top, DefPinButtonSize + 2 * DefMargin);
  if FResizable then
    if Align = alLeft then
      Dec(Rect.Right, EdgeSize)
    else if Align = alRight then
      Inc(Rect.Left, EdgeSize);
end;

procedure TNLDSideBar.AutoHideChanged;
begin
  FPinButton.Down := not FAutoHide;
  if Assigned(FOnAutoHideChanged) then
    FOnAutoHideChanged(Self);
end;

function TNLDSideBar.CanFocus: Boolean;
begin
  if FAutoHide and Enabled and (not Visible) then
  begin
    FSideButton.Activate;
    FMouseOver := True;
    Show;
    Result := True;
  end
  else
    Result := inherited CanFocus;
end;

function TNLDSideBar.CanResize(var NewWidth, NewHeight: Integer): Boolean;
begin
  NewWidth := Max(MinWidth, NewWidth);
  Result := inherited CanResize(NewWidth, NewHeight);
end;

procedure TNLDSideBar.CMEnabledChanged(var Message: TMessage);
begin
  FSideButton.Enabled := Enabled;
end;

procedure TNLDSideBar.CMFontChanged(var Message: TMessage);
begin
  FSideButton.Font.Assign(Font);
end;

procedure TNLDSideBar.CMMouseEnter(var Message: TMessage);
begin
  KillTimer(Handle, 1);
end;

procedure TNLDSideBar.CMMouseLeave(var Message: TMessage);
var
  R: TRect;
begin
  inherited;
  if FAutoHide then
  begin
    if FAlign = alLeft then
      R := Rect(-SideButtonWidth, 0, Width, Height)
    else
      R := Rect(0, 0, Width + SideButtonWidth, Height);
    FMouseOver := PtInRect(R, ScreenToClient(Mouse.CursorPos));
    if not FMouseOver then
      SetTimer(Handle, 1, DefTimerInterval, nil);
  end;
end;

procedure TNLDSideBar.CMParentFontChanged(var Message: TMessage);
begin
  FSideButton.ParentFont := ParentFont;
end;

procedure TNLDSideBar.CMShowHintChanged(var Message: TMessage);
begin
  FSideButton.ShowHint := ShowHint;
end;

procedure TNLDSideBar.CMTextChanged(var Message: TMessage);
begin
  FSideButton.Caption := Caption;
end;

constructor TNLDSideBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := [csAcceptsControls, csCaptureMouse, csClickEvents,
    csSetCaption, csOpaque, csDoubleClicks];
  Color := clBtnFace;
  FSideButton := TNLDSideButton.Create(Self);
  FSideButton.OnClick := SideButtonClicked;
  FSideButton.OnMouseEnter := SideButtonMouseEntered;
  FSideButton.OnMouseLeave := SideButtonMouseLeft;
  FSideButton.OnResize := SideButtonResized;
  SetAlign(alLeft);
  SetBounds(0, 0, DefWidth, 100);
  FMinWidth := DefWidth;
  FResizable := True;
  FPinButton := TSpeedButton.Create(Self);
  with FPinButton do
  begin
    Glyph.LoadFromResourceName(HInstance, SPinButtonBmpResName);
    GroupIndex := -1;
    AllowAllUp := True;
    Down := not FAutoHide;
    Anchors := [akTop, akRight];
    SetBounds(DefWidth - DefPinButtonSize - DefMargin, DefMargin,
      DefPinButtonSize, DefPinButtonSize);
    OnClick := PinButtonClicked;
    Flat := True;
    Parent := Self;
  end;
end;

procedure TNLDSideBar.Delayed;
begin
  if Showing then
  begin
    FSideButton.Deactivate;
    Hide;
  end
  else
  begin
    FSideButton.Activate;
    Show;
  end;
end;

function TNLDSideBar.GetAutoHide: Boolean;
begin
  if csDesigning in ComponentState then
    Result := FStreamedAutoHide
  else
    Result := FAutoHide;
end;

function TNLDSideBar.GetHint: String;
begin
  Result := inherited Hint;
end;

function TNLDSideBar.GetHoverPosition(X: Integer): THoverPosition;
begin
  if (Align = alLeft) and (X > Width - EdgeSize) then
    Result := hpRight
  else if (Align = alRight) and (X < EdgeSize) then
    Result := hpLeft
  else
    Result := hpMiddle;
end;

function TNLDSideBar.GetPinButtonVisible: Boolean;
begin
  Result := FPinButton.Visible;
end;

function TNLDSideBar.GetSideButtonWidth: Integer;
begin
  Result := FSideButton.Width;
end;

procedure TNLDSideBar.Hide;
begin
  inherited Hide;
  if Assigned(FOnHide) then
    FOnHide(Self);
end;

procedure TNLDSideBar.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  if FResizable and (ssLeft in Shift) then
  begin
    OldLeft := Left;
    OldWidth := Width;
    OldX := X;
    case GetHoverPosition(X) of
      hpLeft:
        SizingEdge := seLeft;
      hpRight:
        SizingEdge := seRight;
    end;
  end;
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TNLDSideBar.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewLeft: Integer;
  NewWidth: Integer;
begin
  case SizingEdge of
    seNone:
      if FResizable and (GetHoverPosition(X) in [hpLeft, hpRight]) then
        Cursor := crSizeWE
      else
        Cursor := crDefault;
    seLeft:
      begin
        NewLeft := Min(Left + Width - MinWidth, Left + X - OldX);
        NewWidth := OldWidth + OldLeft - NewLeft;
        SetBounds(NewLeft, Top, NewWidth, Height);
      end;
    seRight:
      Width := Max(FMinWidth, OldWidth - OldX + X);
  end;
  inherited MouseMove(Shift, X, Y);
end;

procedure TNLDSideBar.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  SizingEdge := seNone;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TNLDSideBar.Paint;
var
  R: TRect;
  FontHeight: Integer;
  Flags: Longint;
begin
  R := Rect(0, 0, Width, Height);
  with Canvas do
  begin
    Brush.Style := bsSolid;
    Brush.Color := Color;
    Pen.Color := clBtnShadow;
    Rectangle(R);
    Font := Self.Font;
    FontHeight := TextHeight('Wg');
    if PinButtonVisible then
      R := Rect(1 + DefMargin, 1 + DefMargin,
        Width - DefPinButtonSize - 2 * DefMargin - 2, DefMargin + FontHeight)
    else
      R := Rect(1 + DefMargin, 1 + DefMargin,
        Width - DefMargin - 2, DefMargin + FontHeight);
    Flags := DT_EXPANDTABS or DT_LEFT;
    Flags := DrawTextBiDiModeFlags(Flags);
    DrawText(Handle, PChar(Caption), -1, R, Flags);
    Pen.Color := clBtnShadow;
    MoveTo(R.Left, R.Bottom + DefMargin);
    LineTo(R.Right, PenPos.Y);
  end;
end;

procedure TNLDSideBar.PinButtonClicked(Sender: TObject);
begin
  FMouseOver := True;
  SetAutoHide(not FPinButton.Down);
end;

procedure TNLDSideBar.SetAlign(Value: TSideBarAlign);
begin
  if FAlign <> Value then
  begin
    FAlign := Value;
    UpdateDocking;
  end;
end;

procedure TNLDSideBar.SetAutoHide(Value: Boolean);
begin
  if csDesigning in ComponentState then
    FStreamedAutoHide := Value
  else
    if FAutoHide <> Value then
    begin
      FAutoHide := Value;
      UpdateDocking;
      AutoHideChanged;
    end;
end;

procedure TNLDSideBar.SetHint(const Value: String);
begin
  inherited Hint := Value;
  FSideButton.Hint := Value;
end;

procedure TNLDSideBar.SetMinWidth(const Value: Integer);
begin
  if FMinWidth <> Value then
  begin
    FMinWidth := Value;
    Width := Max(FMinWidth, Width);
  end;
end;

procedure TNLDSideBar.SetParent(AParent: TWinControl);
begin
  inherited SetParent(AParent);
  if (Parent <> nil) and not (csDesigning in ComponentState) then
    FSideButton.Parent := Parent;
end;

procedure TNLDSideBar.SetPinButtonDownHint(const Value: String);
begin
  if FPinButtonDownHint <> Value then
  begin
    FPinButtonDownHint := Value;
    UpdatePinButtonHint;
  end;
end;

procedure TNLDSideBar.SetPinButtonUpHint(const Value: String);
begin
  if FPinButtonUpHint <> Value then
  begin
    FPinButtonUpHint := Value;
    UpdatePinButtonHint;
  end;
end;

procedure TNLDSideBar.SetPinButtonVisible(Value: Boolean);
begin
  FPinButton.Visible := Value;
end;

procedure TNLDSideBar.SetResizable(Value: Boolean);
begin
  if FResizable <> Value then
  begin
    FResizable := Value;
    AdjustSize;
  end;
end;

procedure TNLDSideBar.SetSideButtonWidth(Value: Integer);
begin
  FSideButton.Width := Value;
end;

procedure TNLDSideBar.SideButtonClicked(Sender: TObject);
begin
  KillTimer(Handle, 1);
  FSideButton.Activate;
  Show;
end;

procedure TNLDSideBar.SideButtonMouseEntered(Sender: TObject);
begin
  if not Showing then
    SetTimer(Handle, 1, DefTimerInterval, nil);
end;

procedure TNLDSideBar.SideButtonMouseLeft(Sender: TObject);
begin
  KillTimer(Handle, 1);
end;

procedure TNLDSideBar.SideButtonResized(Sender: TObject);
begin
  UpdatePlacement;
end;

procedure TNLDSideBar.UpdateDocking;
begin
  FSideButton.Align := FAlign;
  FSideButton.Visible := FAutoHide;
  if FAutoHide then
  begin
    if not FMouseOver then
      Hide;
    inherited Align := alCustom;
    UpdatePlacement;
  end
  else
  begin
    inherited Align := FAlign;
    Show;
  end;
end;

procedure TNLDSideBar.UpdatePinButtonHint;
begin
  if FPinButton.Down then
    FPinButton.Hint := FPinButtonDownHint
  else
    FPinButton.Hint := FPinButtonUpHint;
end;

procedure TNLDSideBar.UpdatePlacement;
begin
  if FAutoHide then
    if FAlign = alLeft then
    begin
      SetBounds(FSideButton.Width, FSideButton.Top, Width, FSideButton.Height);
      Anchors := [akLeft, akTop, akBottom];
      BringToFront;
    end
    else
    begin
      SetBounds(FSideButton.Left - Width, FSideButton.Top, Width,
        FSideButton.Height);
      Anchors := [akRight, akTop, akBottom];
      BringToFront;
    end;
end;

procedure TNLDSideBar.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TNLDSideBar.WndProc(var Message: TMessage);
begin
  if Message.Msg = WM_TIMER then
  begin
    KillTimer(Handle, 1);
    Delayed;
  end
  else
    inherited WndProc(Message);
end;

end.
