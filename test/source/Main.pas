unit Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.TabControl,
  FMX.StdCtrls, FMX.Gestures, FMX.Controls.Presentation, FMX.EditBox,
  FMX.NumberBox, FMX.Edit, FMX.Layouts, System.Rtti, FMX.Grid.Style,
  FMX.ScrollBox, FMX.Grid, FMX.Memo, FMX.Ani, FMX.Objects, System.Threading, bruteforce;

type
  TIoTLogType = (ltUnknown, ltInfo, ltAlert, ltError);
  TProgressCallback = procedure(Password: string; Total: Int64; Done: Int64; ToDo: Int64; ErrMsg: string = '') of object;

  TfrmMain = class(TForm)
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    TabItem3: TTabItem;
    GestureManager1: TGestureManager;
    Layout1: TLayout;
    Label1: TLabel;
    txtCharacters: TEdit;
    Label2: TLabel;
    txtMinLength: TNumberBox;
    txtMaxLength: TNumberBox;
    Label3: TLabel;
    txtStoAt: TNumberBox;
    Label4: TLabel;
    grdOutputBT: TStringGrid;
    colPassword: TStringColumn;
    Layout2: TLayout;
    cmdStartBT: TButton;
    cmdReset: TButton;
    txtLog: TMemo;
    panWait: TPanel;
    layWait: TLayout;
    prgWait: TProgressBar;
    imgWait: TImage;
    FloatAnimation1: TFloatAnimation;
    lblWait: TLabel;
    cmdStop: TButton;
    labWaitDone: TLabel;
    lblWaitToDo: TLabel;
    lblWaitTotal: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormGesture (
                            Sender: TObject;
                            const EventInfo: TGestureEventInfo;
                            var Handled: Boolean
                          );
    procedure grdOutputBTResized(Sender: TObject);
    procedure ProgressCallback(Password: string; Total: Int64; Done: Int64; ToDo: Int64; ErrMsg: string = '');
    procedure cmdStopClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure cmdStartBTClick(Sender: TObject);
    procedure cmdResetClick(Sender: TObject);
  private
    CurrTask: ITask;
    Bruteforce: TBruteForce;
    BruteforceDict: TBruteForceEx;
    BruteforceFile: TBruteForce;
    procedure AddRow(StringGrid: TStringGrid; Value: string);
    procedure ClearRows(StringGrid: TStringGrid);
    procedure Log(const Msg: string; LogType: TIoTLogType = TIoTLogType.ltInfo);
    procedure TaskFinished;
    function ValidateBruteforce: boolean;
  public
    procedure CancelTask(Task: ITask);
  end;

var
  frmMain: TfrmMain;


procedure DoBruteForce  (
                        var BruteForce: TBruteForce;
                        ProgressCallback: TProgressCallback;
                        MaxCount: Int64 = 0;
                        TaskFinishedCallBack: TThreadProcedure = nil
                      );


implementation

{$R *.fmx}

procedure DoBruteForce  (
                        var BruteForce: TBruteForce;
                        ProgressCallback: TProgressCallback;
                        MaxCount: Int64 = 0;
                        TaskFinishedCallBack: TThreadProcedure = nil
                      );
var
  Count: Int64;
  LocalBruteforce: TBruteforce;

begin


  try
    try
      Count := 0;
      while (not BruteForce.Last) and ((MaxCount = 0) or (Count < MaxCount)) do
      begin
        LocalBruteforce := BruteForce;
        TThread.Synchronize (
                              TThread.CurrentThread,
                              procedure
                              begin
                                ProgressCallback(LocalBruteforce.Next, LocalBruteforce.Total, LocalBruteforce.Done, LocalBruteforce.ToDo);
                              end
        );
        Inc(Count);
      end;
    except
      on E: Exception do
        TThread.Synchronize (
                              TThread.CurrentThread,
                              procedure
                              begin
                                ProgressCallback('', 0, 0, 0, E.Message);
                              end
        );
    end;
  finally
      if Assigned(TaskFinishedCallBack) then
        TThread.Synchronize(TThread.CurrentThread, TaskFinishedCallBack);
  end;

end;

procedure TfrmMain.AddRow(StringGrid: TStringGrid; Value: string);
begin

    StringGrid.RowCount := StringGrid.RowCount + 1;
    StringGrid.Cells[0, StringGrid.RowCount - 1] := Value;

end;

procedure TfrmMain.CancelTask(Task: ITask);
begin

  if Assigned(Task) then
  begin
    Task.Cancel;
    repeat
      if not Task.Wait(1000) then
        CheckSynchronize;
    until Task = nil;
  end;

end;

procedure TfrmMain.ClearRows(StringGrid: TStringGrid);
begin

  StringGrid.BeginUpdate;
  StringGrid.RowCount := 0;
  StringGrid.EndUpdate;

end;

procedure TfrmMain.cmdResetClick(Sender: TObject);
begin

  if Assigned(Bruteforce) then
    Bruteforce.Reset;

  ClearRows(grdOutputBT);

end;

procedure TfrmMain.cmdStartBTClick(Sender: TObject);
begin

  if not ValidateBruteforce then
    Exit;

  try
    Application.ProcessMessages;
    cmdStartBT.Enabled := false;
    TabControl1.Enabled := false;
    Log('Bruteforce start...');
    prgWait.Max := 0;
    prgWait.Value := 0;
    panWait.Visible := true;
    Application.ProcessMessages;
    grdOutputBT.BeginUpdate;
    try
      CurrTask := TTask.Create (
                      procedure
                      begin
                        DoBruteForce  (
                                      Bruteforce,
                                      ProgressCallback,
                                      StrToInt(txtStoAt.Text),
                                      TaskFinished
                                    );
                      end
                    ).Start;
      while Assigned(CurrTask) and (not (CurrTask.Status in [TTaskStatus.Completed, TTaskStatus.Canceled, TTaskStatus.Exception])) do
        Application.ProcessMessages;
    finally
      Log(Format('Completed bruteforce for %d passwords on %d', [Bruteforce.Done, Bruteforce.Total]));
      grdOutputBT.EndUpdate;
      panWait.Visible := false;
      TabControl1.Enabled := true;
      cmdStartBT.Enabled := true;
      Application.ProcessMessages;
    end;
  except
    on E: Exception do
      Log(E.Message, ltError);
  end;

end;

procedure TfrmMain.cmdStopClick(Sender: TObject);
begin

  try
    CancelTask(CurrTask);
  except
    on E: Exception do
      Log('Process ended by user.');
  end;

end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin

  TabControl1.Enabled := false;
  Application.ProcessMessages;
//  SaveSettings;

  if Assigned(CurrTask) then
  begin
    try
      CancelTask(CurrTask);
    except
      on E: Exception do
      begin
        Log('Closing...');
      end;
    end;
  end;

  Action := TCloseAction.caFree;

end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin

  CurrTask := nil;
  Bruteforce := nil;
  BruteforceDict := nil;
  BruteforceFile := nil;
  TabControl1.ActiveTab := TabItem1;
  txtStoAt.Max := High(integer);

end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin

  CancelTask(CurrTask);

end;

procedure TfrmMain.FormGesture  (
                                  Sender: TObject;
                                  const EventInfo: TGestureEventInfo;
                                  var Handled: Boolean
                                );
begin
{$IFDEF ANDROID}
  case EventInfo.GestureID of
    sgiLeft:
    begin
      if TabControl1.ActiveTab <> TabControl1.Tabs[TabControl1.TabCount-1] then
        TabControl1.ActiveTab := TabControl1.Tabs[TabControl1.TabIndex+1];
      Handled := True;
    end;

    sgiRight:
    begin
      if TabControl1.ActiveTab <> TabControl1.Tabs[0] then
        TabControl1.ActiveTab := TabControl1.Tabs[TabControl1.TabIndex-1];
      Handled := True;
    end;
  end;
{$ENDIF}
end;

procedure TfrmMain.grdOutputBTResized(Sender: TObject);
begin

  colPassword.Width := grdOutputBT.Width - 20;

end;

procedure TfrmMain.Log(const Msg: string; LogType: TIoTLogType);
var
  Log: string;

begin

  if Trim(Msg) <> '' then
  begin
    Log := Format('[%s] ', [DateTimeToStr(Now)]);
    case LogType of
      TIoTLogType.ltAlert : Log := Log + '(ALERT) ';
      TIoTLogType.ltError : Log := Log + '(ERROR) ';
    end;
    Log := Log + Trim(Msg);
    txtLog.Lines.Add(Log);
    txtLog.GoToTextEnd;
    Application.ProcessMessages;
  end;

end;

procedure TfrmMain.ProgressCallback(Password: string; Total, Done, ToDo: Int64; ErrMsg: string = '');
begin

  if Assigned(CurrTask) then
    CurrTask.CheckCanceled;

  if ErrMsg <> '' then
  begin
    Log(ErrMsg, TIoTLogType.ltError);
    Exit;
  end;

  if Total > 0 then
  begin
    prgWait.Max := Total;
    prgWait.Value := Done;
    labWaitDone.Text := Format('Done : %d', [Done]);
    lblWaitToDo.Text := Format('To do: %d', [ToDo]);
    lblWaitTotal.Text := Format('Total: %d', [Total]);
    AddRow(grdOutputBT, Password);
    Application.ProcessMessages;
  end;

end;

procedure TfrmMain.TaskFinished;
begin

  CurrTask := nil;

end;

function TfrmMain.ValidateBruteforce: boolean;
var
  Characters: string;
  MinLength, MaxLength: smallint;
  BruteforceTest: TBruteforce;

begin

  Result := true;

  try
//    cmdStartBT.Enabled := true;
    Characters := txtCharacters.Text;
    MinLength := StrToInt(txtMinLength.Text);
    MaxLength := StrToInt(txtMaxLength.Text);
    if Assigned(Bruteforce) then
    begin
      if  (Characters <> Bruteforce.Characters)
          or (MinLength <> Bruteforce.MinLength)
          or (MaxLength <> Bruteforce.MaxLength)
      then
      begin
        BruteforceTest := TBruteforce.Create(Characters, MinLength, MaxLength);
        try
          FreeAndNil(Bruteforce);
          Result := ValidateBruteforce;
        finally
          BruteforceTest.Free;
        end;
      end
    end
    else
    begin
      Bruteforce := TBruteforce.Create(Characters, MinLength, MaxLength);
      ClearRows(grdOutputBT);
    end;
    if (Bruteforce.Total > txtStoAt.Max) and (StrToInt(txtStoAt.Text) < txtStoAt.Max)  then
      txtStoAt.Text := FloatToStr(txtStoAt.Max);
  except
    on E: Exception do
    begin
      Result := false;
//      cmdStartBT.Enabled := false;
      Log(E.Message, ltError);
    end;
  end;

end;

end.
