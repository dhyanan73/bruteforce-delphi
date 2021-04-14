unit Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.TabControl,
  FMX.StdCtrls, FMX.Gestures, FMX.Controls.Presentation, FMX.EditBox,
  FMX.NumberBox, FMX.Edit, FMX.Layouts, System.Rtti, FMX.Grid.Style,
  FMX.ScrollBox, FMX.Grid, FMX.Memo, FMX.Ani, FMX.Objects, System.Threading, bruteforce,
  System.ImageList, FMX.ImgList, FMX.ListBox;

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
    Layout3: TLayout;
    ImageList1: TImageList;
    Label5: TLabel;
    Layout5: TLayout;
    cmdSelDir: TButton;
    txtDirectory: TEdit;
    Label6: TLabel;
    txtFileName: TEdit;
    txtSeparator: TEdit;
    Label7: TLabel;
    txtMaxItems: TNumberBox;
    Label8: TLabel;
    chkShuffle: TCheckBox;
    cboData: TComboBox;
    Label9: TLabel;
    Layout6: TLayout;
    cmdStartFILE: TButton;
    cmdResetFILE: TButton;
    Layout7: TLayout;
    txtLog: TMemo;
    cmdClearLog: TButton;
    chkBackup: TCheckBox;
    stbMain: TStatusBar;
    lblAbout: TLabel;
    procedure AddRowToPasswordDict(Row: string);
    procedure AddRowToUserNameDict(Row: string);
    procedure FormCreate(Sender: TObject);
    procedure FormGesture (
                            Sender: TObject;
                            const EventInfo: TGestureEventInfo;
                            var Handled: Boolean
                          );
    procedure grdOutputBTResized(Sender: TObject);
    procedure BFProgressCallback(Password: string; Total: Int64; Done: Int64; ToDo: Int64; ErrMsg: string = '');
    procedure DICTProgressCallback(Password: TCredentials; Total: Int64; Done: Int64; ToDo: Int64; ErrMsg: string = '');
    procedure CreateDictionaryCallback  (
                                          Total, Done, ToDo: Int64;
                                          TotalFiles, FilesDone, FilesToDo: integer;
                                          var Stop: boolean;
                                          ErrMsg: string = '';
                                          Msg: string = ''
                                        );
    procedure LoadListCallback  (
                                      Total, Done, ToDo: Int64;
                                      var Stop: boolean;
                                      ErrMsg: string = ''
                                  );
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
    procedure cmdStartFILEClick(Sender: TObject);
    procedure cmdSelDirClick(Sender: TObject);
    procedure cmdResetFILEClick(Sender: TObject);
    procedure cmdClearLogClick(Sender: TObject);
    procedure chkShufflePaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure stbMainClick(Sender: TObject);
  private
    CurrTask: ITask;
    Bruteforce: TBruteForce;
    BruteforceDict: TBruteForceEx;
    LastData: smallint;
    procedure Log(const Msg: string; LogType: TIoTLogType = TIoTLogType.ltInfo);
    procedure TaskFinished;
    function ValidateBruteforce: boolean;
    function ValidateDictionary: boolean;
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
  , System.TimeSpan

{$IF Defined(MSWINDOWS)}
  , Winapi.Windows
  , Winapi.ShellAPI
{$ENDIF}

  ;

procedure ShellCommand(const Command: string);
{$IF Defined(ANDROID)}
var
  Intent: JIntent;
{$ENDIF}

begin

{$IF Defined(ANDROID)}
  Intent := TJIntent.Create;
  Intent.setAction(TJIntent.JavaClass.ACTION_VIEW);
  Intent.setData(StrToJURI(Command));
  tandroidhelper.Activity.startActivity(Intent);
  // SharedActivity.startActivity(Intent);
{$ELSEIF Defined(MSWINDOWS)}
  ShellExecute(0, 'OPEN', PWideChar(Command), nil, nil, SW_SHOWNORMAL);
{$ELSEIF Defined(IOS)}
  SharedApplication.OpenURL(StrToNSUrl(Command));
{$ELSEIF Defined(MACOS)}
  _system(PAnsiChar('open ' + AnsiString(Command)));
{$ENDIF}

end;

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

procedure TfrmMain.chkShufflePaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
begin

  if chkBackup.Enabled <> chkShuffle.IsChecked then
  begin
    chkBackup.Enabled := chkShuffle.IsChecked;
    if not chkBackup.Enabled then
      chkBackup.IsChecked := false;
  end;

end;

procedure TfrmMain.cmdAddPasswordDicClick(Sender: TObject);
var
  Stopwatch: TStopwatch;

begin

  try
    Application.ProcessMessages;
    cmdLoadPasswordDic.Enabled := false;
    tabMain.Enabled := false;
    Log('Start adding password dictionary...');
    labWaitDone.Visible := false;
    lblWaitToDo.Visible := false;
    lblWaitTotal.Visible := false;
    prgWait.Max := 0;
    prgWait.Value := 0;
    try
      txtLog.SetFocus;
      grdPasswordDict.BeginUpdate;
      try
        Stopwatch := TStopwatch.StartNew;
        if Assigned(CurrTask) then
          CurrTask := nil;
        CurrTask := TTask.Create (
                        procedure
                        begin
                          LoadFileToStringList(dlgOpenFile, AddRowToPasswordDict, LoadListCallback, TaskFinished);
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
        grdPasswordDict.EndUpdate;
      end;
    finally
      lblPasswordDicCount.Text := IntTostr(grdPasswordDict.RowCount) + ' items';
      Log(Format  (
                    'Added %d rows in password dictionary in %s',
                    [
                      grdPasswordDict.RowCount,
                      HumanElapsedTime(Trunc(Stopwatch.Elapsed.TotalMilliseconds))
                    ]
                  ));
      panWait.Visible := false;
      labWaitDone.Visible := true;
      lblWaitToDo.Visible := true;
      lblWaitTotal.Visible := true;
      tabMain.Enabled := true;
      cmdLoadPasswordDic.Enabled := true;
      Application.ProcessMessages;
    end;
  except
    on E: Exception do
      Log(E.Message, ltError);
  end;

end;

procedure TfrmMain.cmdAddUserNameDicClick(Sender: TObject);
var
  Stopwatch: TStopwatch;

begin

  try
    Application.ProcessMessages;
    cmdLoadUserNameDic.Enabled := false;
    tabMain.Enabled := false;
    Log('Start adding user name dictionary...');
    labWaitDone.Visible := false;
    lblWaitToDo.Visible := false;
    lblWaitTotal.Visible := false;
    prgWait.Max := 0;
    prgWait.Value := 0;
    try
      txtLog.SetFocus;
      grdUsernameDict.BeginUpdate;
      try
        Stopwatch := TStopwatch.StartNew;
        if Assigned(CurrTask) then
          CurrTask := nil;
        CurrTask := TTask.Create (
                        procedure
                        begin
                          LoadFileToStringList(dlgOpenFile, AddRowToUserNameDict, LoadListCallback, TaskFinished);
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
        grdUsernameDict.EndUpdate;
      end;
    finally
      lblUserNameDicCount.Text := IntTostr(grdUsernameDict.RowCount) + ' items';
      Log(Format  (
                    'Added %d rows in username dictionary in %s',
                    [
                      grdUsernameDict.RowCount,
                      HumanElapsedTime(Trunc(Stopwatch.Elapsed.TotalMilliseconds))
                    ]
                  ));
      panWait.Visible := false;
      labWaitDone.Visible := true;
      lblWaitToDo.Visible := true;
      lblWaitTotal.Visible := true;
      tabMain.Enabled := true;
      cmdLoadUserNameDic.Enabled := true;
      Application.ProcessMessages;
    end;
  except
    on E: Exception do
      Log(E.Message, ltError);
  end;

end;

procedure TfrmMain.cmdClearLogClick(Sender: TObject);
begin

  cmdClearLog.Enabled := false;

  try
    txtLog.Lines.BeginUpdate;
    try
      txtLog.Lines.Clear;
    finally
      txtLog.Lines.EndUpdate;
    end;
    Application.ProcessMessages;
  finally
    cmdClearLog.Enabled := true;
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
var
  Stopwatch: TStopwatch;

begin

  try
    Application.ProcessMessages;
    cmdLoadPasswordDic.Enabled := false;
    tabMain.Enabled := false;
    Log('Start loading password dictionary...');
    labWaitDone.Visible := false;
    lblWaitToDo.Visible := false;
    lblWaitTotal.Visible := false;
    prgWait.Max := 0;
    prgWait.Value := 0;
    try
      ClearRows(grdPasswordDict);
      txtLog.SetFocus;
      grdPasswordDict.BeginUpdate;
      try
        Stopwatch := TStopwatch.StartNew;
        if Assigned(CurrTask) then
          CurrTask := nil;
        CurrTask := TTask.Create (
                        procedure
                        begin
                          LoadFileToStringList(dlgOpenFile, AddRowToPasswordDict, LoadListCallback, TaskFinished);
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
        grdPasswordDict.EndUpdate;
      end;
    finally
      lblPasswordDicCount.Text := IntTostr(grdPasswordDict.RowCount) + ' items';
      Log(Format  (
                    'Loaded %d rows in password dictionary in %s',
                    [
                      grdPasswordDict.RowCount,
                      HumanElapsedTime(Trunc(Stopwatch.Elapsed.TotalMilliseconds))
                    ]
                  ));
      panWait.Visible := false;
      labWaitDone.Visible := true;
      lblWaitToDo.Visible := true;
      lblWaitTotal.Visible := true;
      tabMain.Enabled := true;
      cmdLoadPasswordDic.Enabled := true;
      Application.ProcessMessages;
    end;
  except
    on E: Exception do
      Log(E.Message, ltError);
  end;

end;

procedure TfrmMain.cmdLoadUserNameDicClick(Sender: TObject);
var
  Stopwatch: TStopwatch;

begin

  try
    Application.ProcessMessages;
    cmdLoadUserNameDic.Enabled := false;
    tabMain.Enabled := false;
    Log('Start loading user name dictionary...');
    labWaitDone.Visible := false;
    lblWaitToDo.Visible := false;
    lblWaitTotal.Visible := false;
    prgWait.Max := 0;
    prgWait.Value := 0;
    try
      ClearRows(grdUsernameDict);
      txtLog.SetFocus;
      grdUsernameDict.BeginUpdate;
      try
        Stopwatch := TStopwatch.StartNew;
        if Assigned(CurrTask) then
          CurrTask := nil;
        CurrTask := TTask.Create (
                        procedure
                        begin
                          LoadFileToStringList(dlgOpenFile, AddRowToUserNameDict, LoadListCallback, TaskFinished);
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
        grdUsernameDict.EndUpdate;
      end;
    finally
      lblUserNameDicCount.Text := IntTostr(grdUsernameDict.RowCount) + ' items';
      Log(Format  (
                    'Loaded %d rows in username dictionary in %s',
                    [
                      grdUsernameDict.RowCount,
                      HumanElapsedTime(Trunc(Stopwatch.Elapsed.TotalMilliseconds))
                    ]
                  ));
      panWait.Visible := false;
      labWaitDone.Visible := true;
      lblWaitToDo.Visible := true;
      lblWaitTotal.Visible := true;
      tabMain.Enabled := true;
      cmdLoadUserNameDic.Enabled := true;
      Application.ProcessMessages;
    end;
  except
    on E: Exception do
      Log(E.Message, ltError);
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

procedure TfrmMain.cmdResetFILEClick(Sender: TObject);
var
  BF: TBruteForce;

begin

  BF := nil;

  if cboData.ItemIndex = 0 then
    BF := Bruteforce;

  if cboData.ItemIndex = 1 then
    BF := BruteforceDict;

  if Assigned(BF) then
    BF.Reset;

end;

procedure TfrmMain.cmdSelDirClick(Sender: TObject);
var
  Directory: string;

begin

  if SelectDirectory('Select Directory', '', Directory) then
    txtDirectory.Text := Directory;

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
    prgWait.Visible := false;
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
                                      StrToIntDef(txtStoAt.Text, 2147483008),
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
      prgWait.Visible := false;
      tabMain.Enabled := true;
      cmdStartBT.Enabled := true;
      prgWait.Max := 0;
      prgWait.Value := 0;
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
    prgWait.Visible := false;
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
                                      StrToIntDef(txtStoAt.Text, 2147483008),
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
      prgWait.Visible := false;
      tabMain.Enabled := true;
      cmdStartDICT.Enabled := true;
      prgWait.Max := 0;
      prgWait.Value := 0;
      Application.ProcessMessages;
    end;
  except
    on E: Exception do
      Log(E.Message, ltError);
  end;

end;

procedure TfrmMain.cmdStartFILEClick(Sender: TObject);
var
  Stopwatch: TStopwatch;
  BF: TBruteForce;
  Separator: string;

begin

  if cboData.ItemIndex = 0 then
  begin
    if not ValidateBruteforce then
      Exit;
    BF := Bruteforce;
  end;

  if cboData.ItemIndex = 1 then
  begin
    if not ValidateDictionary then
      Exit;
    BF := BruteforceDict;
  end;

  if LastData <> cboData.ItemIndex then
  begin
    LastData := cboData.ItemIndex;
    cmdResetFILEClick(nil);
    cmdStartFILEClick(nil);
    Exit;
  end;

  try
    Application.ProcessMessages;
    cmdStartFILE.Enabled := false;
    tabMain.Enabled := false;
    Log('Dictionary create start...');
    prgWait.Max := 0;
    prgWait.Value := 0;
    prgWait.Visible := false;
    panWait.Visible := true;
    Application.ProcessMessages;
    try
      txtLog.SetFocus;
      Stopwatch := TStopwatch.StartNew;
      if Assigned(CurrTask) then
        CurrTask := nil;
      if cboData.ItemIndex = 0 then
        CurrTask := TTask.Create (
                        procedure
                        begin
                          BF.CreateDictionary (
                                                txtDirectory.Text,
                                                txtFileName.Text,
                                                CreateDictionaryCallback,
                                                TaskFinished,
                                                StrToIntDef(txtMaxItems.Text, 2147483008),
                                                chkShuffle.IsChecked,
                                                chkBackup.IsChecked
                                              );
                        end
                      ).Start;
      if cboData.ItemIndex = 1 then
      begin
        Separator := txtSeparator.Text;
        CurrTask := TTask.Create (
                        procedure
                        begin
                          TBruteForceEx(BF).CreateDictionary (
                                                                txtDirectory.Text,
                                                                txtFileName.Text,
                                                                Separator,
                                                                CreateDictionaryCallback,
                                                                TaskFinished,
                                                                StrToIntDef(txtMaxItems.Text, 2147483008),
                                                                chkShuffle.IsChecked
                                                              );
                        end
                      ).Start;
      end;
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
                    'Completed dictionary created for %d passwords (%d files) on %d (%d files) in %s',
                    [
                      BF.Done,
                      BF.FilesDone,
                      BF.Total,
                      BF.TotalFiles,
                      HumanElapsedTime(Trunc(Stopwatch.Elapsed.TotalMilliseconds))
                    ]
                  ));
      panWait.Visible := false;
      tabMain.Enabled := true;
      cmdStartFILE.Enabled := true;
      prgWait.Visible := false;
      prgWait.Max := 0;
      prgWait.Value := 0;
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

procedure TfrmMain.CreateDictionaryCallback (
                                              Total, Done, ToDo: Int64;
                                              TotalFiles, FilesDone, FilesToDo: integer;
                                              var Stop: boolean;
                                              ErrMsg: string;
                                              Msg: string
                                            );
begin

  try
    if Assigned(CurrTask) then
      CurrTask.CheckCanceled;
    if ErrMsg <> '' then
    begin
      Log(ErrMsg, TIoTLogType.ltError);
      Exit;
    end;
    if FilesToDo > 0 then
    begin
      labWaitDone.Text := Format('Done : %d (%d files)', [Done, FilesDone]);
      lblWaitToDo.Text := Format('To do: %d (%d files)', [ToDo, FilesToDo]);
      lblWaitTotal.Text := Format('Total: %d (%d files)', [Total, TotalFiles]);
    end
    else
    begin
      labWaitDone.Text := Format('SHUFFLING FILE %d/%d...' + sLineBreak + 'Done : %d', [FilesDone + 1, TotalFiles, Done]);
      lblWaitToDo.Text := Format('To do: %d', [ToDo]);
      lblWaitTotal.Text := Format('Total: %d', [Total]);
    end;
    prgWait.Max := Total;
    prgWait.Value := Done;
    if Msg <> '' then
      Log(Msg);
    Application.ProcessMessages;
  finally
    if (not Stop) <> prgWait.Visible then
      prgWait.Visible := not Stop;
  end;

end;

procedure TfrmMain.DICTProgressCallback(Password: TCredentials; Total, Done, ToDo: Int64; ErrMsg: string);
var
  Stop: boolean;

begin

  Stop := not ((Total > 0) and (ToDo > 0));

  try
    if Assigned(CurrTask) then
      CurrTask.CheckCanceled;
    if ErrMsg <> '' then
    begin
      Stop := true;
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
  finally
    if (not Stop) <> prgWait.Visible then
      prgWait.Visible := not Stop;
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

  LastData := 0;
  CurrTask := nil;
  Bruteforce := nil;
  BruteforceDict := nil;
  tabMain.ActiveTab := tabBruteforce;
  tabDictionaryBF.ActiveTab := tabUsernameDict;
  txtCharacters.SetFocus;

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

  grdOutputDICT.Columns[0].Width := Trunc((grdOutputDICT.Width - 22) / 2);
  grdOutputDICT.Columns[1].Width := Trunc((grdOutputDICT.Width - 22) / 2);

end;

procedure TfrmMain.grdPasswordDictResized(Sender: TObject);
begin

    colPasswordDict.Width := grdUsernameDict.Width - 20;

end;

procedure TfrmMain.grdUsernameDictResized(Sender: TObject);
begin

    colUsernameDict.Width := grdUsernameDict.Width - 20;

end;

procedure TfrmMain.LoadListCallback(Total, Done, ToDo: Int64; var Stop: boolean; ErrMsg: string);
begin

  if not panWait.Visible then
  begin
    panWait.Visible := true;
    Application.ProcessMessages;
  end;

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
    Application.ProcessMessages;
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

procedure TfrmMain.stbMainClick(Sender: TObject);
begin

  ShellCommand('https://github.com/dhyanan73/bruteforce-delphi');

end;

procedure TfrmMain.AddRowToPasswordDict(Row: string);
begin

    grdPasswordDict.RowCount := grdPasswordDict.RowCount + 1;
    grdPasswordDict.Cells[0, grdPasswordDict.RowCount - 1] := Row;

end;

procedure TfrmMain.AddRowToUserNameDict(Row: string);
begin

    grdUsernameDict.RowCount := grdUsernameDict.RowCount + 1;
    grdUsernameDict.Cells[0, grdUsernameDict.RowCount - 1] := Row;

end;

procedure TfrmMain.BFProgressCallback(Password: string; Total, Done, ToDo: Int64; ErrMsg: string = '');
var
  Stop: boolean;

begin

  Stop := not ((Total > 0) and (ToDo > 0));

  try
    if Assigned(CurrTask) then
      CurrTask.CheckCanceled;
    if ErrMsg <> '' then
    begin
      Stop := true;
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
  finally
    if (not Stop) <> prgWait.Visible then
      prgWait.Visible := not Stop;
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
//    if Bruteforce.Total > 2147483008 then
//      txtStoAt.Text := '2147483008';
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
//    if chkBruteforce.IsChecked and (BruteforceDict.Total > 2147483008) then
//      txtStoAt.Text := '2147483008';
  except
    on E: Exception do
    begin
      Result := false;
      Log(E.Message, ltError);
    end;
  end;

end;

end.
