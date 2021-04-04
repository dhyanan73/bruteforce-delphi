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
  TBFProgressCallback = procedure(Password: string; Total: Int64; Done: Int64; ToDo: Int64; ErrMsg: string = '') of object;
  TDICTProgressCallback = procedure(Password: TCredentials; Total: Int64; Done: Int64; ToDo: Int64; ErrMsg: string = '') of object;

  TfrmMain = class(TForm)
    tabMain: TTabControl;
    tabBruteforce: TTabItem;
    tabDictionary: TTabItem;
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
    grdOutputDICT: TStringGrid;
    colOutUsernameDict: TStringColumn;
    layDictionary: TLayout;
    Layout4: TLayout;
    cmdStartDICT: TButton;
    cmdResetDict: TButton;
    tabDictionaryBF: TTabControl;
    tabUsernameDict: TTabItem;
    tabPasswordDict: TTabItem;
    chkBruteforce: TCheckBox;
    StyleBook1: TStyleBook;
    colOutPasswordDict: TStringColumn;
    panUserNameDicCommands: TPanel;
    cmdAddUserNameDic: TButton;
    cmdClearUserNameDic: TButton;
    cmdLoadUserNameDic: TButton;
    lblUserNameDicCount: TLabel;
    panPasswordCommands: TPanel;
    cmdAddPasswordDic: TButton;
    cmdClearPasswordDic: TButton;
    cmdLoadPasswordDic: TButton;
    lblPasswordDicCount: TLabel;
    grdUsernameDict: TStringGrid;
    colUsernameDict: TStringColumn;
    grdPasswordDict: TStringGrid;
    colPasswordDict: TStringColumn;
    dlgOpenFile: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormGesture (
                            Sender: TObject;
                            const EventInfo: TGestureEventInfo;
                            var Handled: Boolean
                          );
    procedure grdOutputBTResized(Sender: TObject);
    procedure BFProgressCallback(Password: string; Total: Int64; Done: Int64; ToDo: Int64; ErrMsg: string = '');
    procedure DICTProgressCallback(Password: TCredentials; Total: Int64; Done: Int64; ToDo: Int64; ErrMsg: string = '');
    procedure cmdStopClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure cmdStartBTClick(Sender: TObject);
    procedure cmdResetClick(Sender: TObject);
    procedure grdOutputDICTResized(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure grdUsernameDictResized(Sender: TObject);
    procedure grdPasswordDictResized(Sender: TObject);
    procedure cmdLoadUserNameDicClick(Sender: TObject);
    procedure cmdClearUserNameDicClick(Sender: TObject);
    procedure cmdAddUserNameDicClick(Sender: TObject);
    procedure cmdLoadPasswordDicClick(Sender: TObject);
    procedure cmdAddPasswordDicClick(Sender: TObject);
    procedure cmdClearPasswordDicClick(Sender: TObject);
    procedure cmdResetDictClick(Sender: TObject);
    procedure cmdStartDICTClick(Sender: TObject);
  private
    CurrTask: ITask;
    Bruteforce: TBruteForce;
    BruteforceDict: TBruteForceEx;
    procedure Log(const Msg: string; LogType: TIoTLogType = TIoTLogType.ltInfo);
    procedure TaskFinished;
    function ValidateBruteforce: boolean;
    function ValidateDictionary: boolean;
    function OpenFile: string;
    procedure LoadRowsFromFile(StringGrid: TStringGrid);
  public
    procedure CancelTask(Task: ITask);
  end;

var
  frmMain: TfrmMain;


implementation

{$R *.fmx}
{$R *.Windows.fmx MSWINDOWS}

uses
  System.Diagnostics
  , System.TimeSpan;

function StrArraysEquals(Array1: TArray<string>; Array2: TArray<string>): boolean;
var
  MinIndex, MaxIndex, I: integer;

begin

  Result := ((not Assigned(Array1)) and (not Assigned(Array2))) or (Assigned(Array1) and Assigned(Array2));

  if Result and Assigned(Array1) then
  begin
    MinIndex := Low(Array1);
    MaxIndex := High(Array1);
    Result := (MinIndex = Low(Array2)) and (MaxIndex = High(Array2));
    if Result then
      for I := MinIndex to MaxIndex do
        if Array1[I] <> Array2[I] then
          Exit(false);
  end;

end;

function StringGridColToArray(Grid: TStringGrid; Column: integer = 0): TArray<string>;
var
  Rows, I: integer;

begin

  Rows := Grid.RowCount;
  SetLength(Result, Rows);

  for I := 0 to Rows - 1 do
    Result[I] := Grid.Cells[Column, I];

end;

procedure ClearRows(StringGrid: TCustomGrid);
begin

  StringGrid.BeginUpdate;
  StringGrid.RowCount := 0;
  StringGrid.EndUpdate;

end;

procedure AddRow(StringGrid: TStringGrid; Value: string); overload;
begin

    StringGrid.RowCount := StringGrid.RowCount + 1;
    StringGrid.Cells[0, StringGrid.RowCount - 1] := Value;

end;

procedure AddRow(StringGrid: TStringGrid; Value: TCredentials); overload;
begin

    StringGrid.RowCount := StringGrid.RowCount + 1;
    StringGrid.Cells[0, StringGrid.RowCount - 1] := Value[0];
    StringGrid.Cells[1, StringGrid.RowCount - 1] := Value[1];

end;

function HumanElapsedTime(Milliseconds: Int64; ShowInfo: boolean = true): string;
var
  Ms: Int64;
  Seconds: Int64;
  Minutes: Int64;
  Hours: Int64;
  Days: Int64;

begin

  Ms := 0;
  Seconds := 0;
  Minutes := 0;
  Hours := 0;
  Days := 0;

  if Milliseconds > 0 then
  begin
    Seconds := Trunc(Milliseconds / 1000);
    Ms := Milliseconds mod 1000;
    Minutes := Trunc(Seconds / 60);
    Seconds := Seconds mod 60;
    Hours := Trunc(Minutes / 60);
    Minutes := Minutes mod 60;
    Days := Trunc(Hours / 24);
    Hours := Hours mod 24;
  end;

  Result := Format('%d:%d:%d:%d:%d', [Days, Hours, Minutes, Seconds, Ms]);

  if ShowInfo then
    Result := Result + ' (days:hours:minutes:seconds:milliseconds)';

end;

procedure DoBruteForce  (
                        var BruteForce: TBruteForce;
                        ProgressCallback: TBFProgressCallback;
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

procedure DoDictionary  (
                        var BruteForceEx: TBruteForceEx;
                        ProgressCallback: TDICTProgressCallback;
                        MaxCount: Int64 = 0;
                        TaskFinishedCallBack: TThreadProcedure = nil
                      );
var
  Count: Int64;
  LocalBruteforce: TBruteForceEx;
  TmpCredentials: TCredentials;

begin

  try
    try
      Count := 0;
      while (not BruteForceEx.Last) and ((MaxCount = 0) or (Count < MaxCount)) do
      begin
        LocalBruteforce := BruteForceEx;
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
                                ProgressCallback(TmpCredentials, 0, 0, 0, E.Message);
                              end
        );
    end;
  finally
      if Assigned(TaskFinishedCallBack) then
        TThread.Synchronize(TThread.CurrentThread, TaskFinishedCallBack);
  end;

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

procedure TfrmMain.cmdAddPasswordDicClick(Sender: TObject);
begin

  cmdLoadPasswordDic.Enabled := false;

  try
    LoadRowsFromFile(grdPasswordDict);
    lblPasswordDicCount.Text := IntTostr(grdPasswordDict.RowCount) + ' items';
  finally
    cmdLoadPasswordDic.Enabled := true;
  end;

end;

procedure TfrmMain.cmdAddUserNameDicClick(Sender: TObject);
begin

  cmdLoadUserNameDic.Enabled := false;

  try
    LoadRowsFromFile(grdUsernameDict);
    lblUserNameDicCount.Text := IntTostr(grdUsernameDict.RowCount) + ' items';
  finally
    cmdLoadUserNameDic.Enabled := true;
  end;

end;

procedure TfrmMain.cmdClearPasswordDicClick(Sender: TObject);
begin

  cmdClearPasswordDic.Enabled := false;

  try
    ClearRows(grdPasswordDict);
    lblPasswordDicCount.Text := IntTostr(grdPasswordDict.RowCount) + ' items';
  finally
    cmdClearPasswordDic.Enabled := true;
  end;

end;

procedure TfrmMain.cmdClearUserNameDicClick(Sender: TObject);
begin

  cmdClearUserNameDic.Enabled := false;

  try
    ClearRows(grdUsernameDict);
    lblUserNameDicCount.Text := IntTostr(grdUsernameDict.RowCount) + ' items';
  finally
    cmdClearUserNameDic.Enabled := true;
  end;

end;

procedure TfrmMain.cmdLoadPasswordDicClick(Sender: TObject);
begin

  cmdLoadPasswordDic.Enabled := false;

  try
    ClearRows(grdPasswordDict);
    LoadRowsFromFile(grdPasswordDict);
    lblPasswordDicCount.Text := IntTostr(grdPasswordDict.RowCount) + ' items';
  finally
    cmdLoadPasswordDic.Enabled := true;
  end;

end;

procedure TfrmMain.cmdLoadUserNameDicClick(Sender: TObject);
begin

  cmdLoadUserNameDic.Enabled := false;

  try
    ClearRows(grdUsernameDict);
    LoadRowsFromFile(grdUsernameDict);
    lblUserNameDicCount.Text := IntTostr(grdUsernameDict.RowCount) + ' items';
  finally
    cmdLoadUserNameDic.Enabled := true;
  end;

end;

procedure TfrmMain.cmdResetClick(Sender: TObject);
begin

  if Assigned(Bruteforce) then
    Bruteforce.Reset;

  ClearRows(grdOutputBT);

end;

procedure TfrmMain.cmdResetDictClick(Sender: TObject);
begin

  if Assigned(BruteforceDict) then
    BruteforceDict.Reset;

  ClearRows(grdOutputDICT);

end;

procedure TfrmMain.cmdStartBTClick(Sender: TObject);
var
  Stopwatch: TStopwatch;

begin

  if not ValidateBruteforce then
    Exit;

  try
    Application.ProcessMessages;
    cmdStartBT.Enabled := false;
    tabMain.Enabled := false;
    Log('Bruteforce start...');
    prgWait.Max := 0;
    prgWait.Value := 0;
    panWait.Visible := true;
    Application.ProcessMessages;
    grdOutputBT.BeginUpdate;
    try
      txtLog.SetFocus;
      Stopwatch := TStopwatch.StartNew;
      if Assigned(CurrTask) then
        CurrTask := nil;
      CurrTask := TTask.Create (
                      procedure
                      begin
                        DoBruteForce  (
                                      Bruteforce,
                                      BFProgressCallback,
                                      StrToIntDef(txtStoAt.Text, MaxInt),
                                      TaskFinished
                                    );
                      end
                    ).Start;
      while
            Assigned(CurrTask)
            and (not  (
                        CurrTask.Status in  [
                                              TTaskStatus.Completed,
                                              TTaskStatus.Canceled,
                                              TTaskStatus.Exception
                                            ]
                      )) do
        Application.ProcessMessages;
    finally
      Log(Format  (
                    'Completed bruteforce for %d passwords on %d in %s',
                    [
                      Bruteforce.Done,
                      Bruteforce.Total,
                      HumanElapsedTime(Trunc(Stopwatch.Elapsed.TotalMilliseconds))
                    ]
                  ));
      grdOutputBT.EndUpdate;
      grdOutputBTResized(nil);
      panWait.Visible := false;
      tabMain.Enabled := true;
      cmdStartBT.Enabled := true;
      Application.ProcessMessages;
    end;
  except
    on E: Exception do
      Log(E.Message, ltError);
  end;

end;

procedure TfrmMain.cmdStartDICTClick(Sender: TObject);
var
  Stopwatch: TStopwatch;

begin

  if not ValidateDictionary then
    Exit;

  try
    Application.ProcessMessages;
    cmdStartDICT.Enabled := false;
    tabMain.Enabled := false;
    Log('Dictionary start...');
    prgWait.Max := 0;
    prgWait.Value := 0;
    panWait.Visible := true;
    Application.ProcessMessages;
    grdOutputDICT.BeginUpdate;
    try
      txtLog.SetFocus;
      Stopwatch := TStopwatch.StartNew;
      if Assigned(CurrTask) then
        CurrTask := nil;
      CurrTask := TTask.Create (
                      procedure
                      begin
                        DoDictionary  (
                                      BruteforceDict,
                                      DICTProgressCallback,
                                      StrToIntDef(txtStoAt.Text, MaxInt),
                                      TaskFinished
                                    );
                      end
                    ).Start;
      while
            Assigned(CurrTask)
            and (not  (
                        CurrTask.Status in  [
                                              TTaskStatus.Completed,
                                              TTaskStatus.Canceled,
                                              TTaskStatus.Exception
                                            ]
                      )) do
        Application.ProcessMessages;
    finally
      Log(Format  (
                    'Completed dictionary for %d passwords on %d in %s',
                    [
                      BruteforceDict.Done,
                      BruteforceDict.Total,
                      HumanElapsedTime(Trunc(Stopwatch.Elapsed.TotalMilliseconds))
                    ]
                  ));
      grdOutputDICT.EndUpdate;
      grdOutputDICTResized(nil);
      panWait.Visible := false;
      tabMain.Enabled := true;
      cmdStartDICT.Enabled := true;
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

procedure TfrmMain.DICTProgressCallback(Password: TCredentials; Total, Done, ToDo: Int64; ErrMsg: string);
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
    AddRow(grdOutputDICT, Password);
    Application.ProcessMessages;
  end;

end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin

  tabMain.Enabled := false;
  Application.ProcessMessages;

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
  tabMain.ActiveTab := tabBruteforce;
  tabDictionaryBF.ActiveTab := tabUsernameDict;
  txtStoAt.Max := MaxInt;

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

procedure TfrmMain.FormResize(Sender: TObject);
begin

  layDictionary.Height := Trunc((Height / 7) * 3);
  Application.ProcessMessages;

end;

procedure TfrmMain.grdOutputBTResized(Sender: TObject);
begin

  colPassword.Width := grdOutputBT.Width - 20;

end;

procedure TfrmMain.grdOutputDICTResized(Sender: TObject);
begin

  grdOutputDICT.Columns[0].Width := Trunc((grdOutputDICT.Width - 20) / 2);
  grdOutputDICT.Columns[1].Width := Trunc((grdOutputDICT.Width - 20) / 2);

end;

procedure TfrmMain.grdPasswordDictResized(Sender: TObject);
begin

    colPasswordDict.Width := grdUsernameDict.Width - 20;

end;

procedure TfrmMain.grdUsernameDictResized(Sender: TObject);
begin

    colUsernameDict.Width := grdUsernameDict.Width - 20;

end;

procedure TfrmMain.LoadRowsFromFile(StringGrid: TStringGrid);
var
  FileName: string;
  LoadedRows: TStringList;
  I: integer;

begin

  FileName := OpenFile();

  if FileExists(FileName) and (FileName <> '') then
  begin
    LoadedRows := TStringList.Create;
    try
      StringGrid.BeginUpdate;
      try
        LoadedRows.BeginUpdate;
        try
          LoadedRows.LoadFromFile(FileName);
        finally
          LoadedRows.EndUpdate;
        end;
        for I := 0 to LoadedRows.Count - 1 do
          AddRow(StringGrid, LoadedRows.Strings[I]);
      finally
        StringGrid.EndUpdate;
      end;
    finally
      LoadedRows.Free;
    end;
  end;

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

function TfrmMain.OpenFile: string;
begin

  Result := '';

  if dlgOpenFile.Execute then
    Result := dlgOpenFile.FileName;

end;

procedure TfrmMain.BFProgressCallback(Password: string; Total, Done, ToDo: Int64; ErrMsg: string = '');
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
    if Bruteforce.Total > MaxInt then
      txtStoAt.Text := IntToStr(MaxInt);
  except
    on E: Exception do
    begin
      Result := false;
      Log(E.Message, ltError);
    end;
  end;

end;

function TfrmMain.ValidateDictionary: boolean;
var
  Characters: string;
  MinLength, MaxLength: smallint;
  BruteforceTest: TBruteforceEx;
  UsernameDictionary, PasswordDictionary: TArray<string>;

begin

  Result := true;

  try
    if chkBruteforce.IsChecked then
    begin
      Characters := txtCharacters.Text;
      MinLength := StrToInt(txtMinLength.Text);
      MaxLength := StrToInt(txtMaxLength.Text);
    end
    else
    begin
      Characters := '';
      MinLength := 0;
      MaxLength := 0;
    end;
    UsernameDictionary := StringGridColToArray(grdUsernameDict);
    if Length(UsernameDictionary) = 0 then
      UsernameDictionary := nil;
    PasswordDictionary := StringGridColToArray(grdPasswordDict);
    if Length(PasswordDictionary) = 0 then
      PasswordDictionary := nil;
    if Assigned(BruteforceDict) then
    begin
      if  (Characters <> BruteforceDict.Characters)
          or (MinLength <> BruteforceDict.MinLength)
          or (MaxLength <> BruteforceDict.MaxLength)
          or (not StrArraysEquals(UsernameDictionary, BruteforceDict.UsernameDictionary))
          or (not StrArraysEquals(PasswordDictionary, BruteforceDict.PasswordDictionary))
      then
      begin
        BruteforceTest := TBruteforceEx.Create  (
                                                  UsernameDictionary,
                                                  PasswordDictionary,
                                                  Characters,
                                                  MinLength,
                                                  MaxLength
                                                );
        try
          FreeAndNil(BruteforceDict);
          Result := ValidateDictionary;
        finally
          BruteforceTest.Free;
        end;
      end
    end
    else
    begin
      BruteforceDict := TBruteforceEx.Create  (
                                                  UsernameDictionary,
                                                  PasswordDictionary,
                                                  Characters,
                                                  MinLength,
                                                  MaxLength
                                                );
      ClearRows(grdOutputDICT);
    end;
    if chkBruteforce.IsChecked and (Bruteforce.Total > MaxInt) then
      txtStoAt.Text := IntToStr(MaxInt);
  except
    on E: Exception do
    begin
      Result := false;
      Log(E.Message, ltError);
    end;
  end;

end;

end.
