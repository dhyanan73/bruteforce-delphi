unit bruteforce;

interface

uses
  System.Classes
  , FMX.Dialogs;

type

  TCredentials = Array[0..1] Of string;
  TCredentialLength = 1..512;
  TCreateDictionaryCallback = procedure (
                                          Total, Done, ToDo: Int64;
                                          TotalFiles, FilesDone, FilesToDo: integer;
                                          var Stop: boolean;
                                          ErrMsg: string = '';
                                          Msg: string = ''
                                        ) of object;
  TBFProgressCallback = procedure (
                                    Total, Done, ToDo: Int64;
                                    var Stop: boolean;
                                    ErrMsg: string = ''
                                  ) of object;
  TBFAddListItemCallback = procedure (Item: string) of object;

  TCustomBruteForce = class
  strict private
    FFileItems: Int64;
    FFileHandler: TextFile;
    FDirectory: string;
    FFileName: string;
    FMaxItemsPerFile: Int64;
    FTotalFiles: integer;
    FFilesToDo: integer;
    FFilesDone: integer;
    FCallback: TCreateDictionaryCallback;
    FFileIndexDigits: smallint;
    function GetDirectory: string;
    function GetFileName: string;
    function GetTotalFiles: integer;
    function GetFilesToDo: integer;
    function GetFilesDone: integer;
    procedure SetDirectory(Value: string);
    procedure SetMaxItemsPerFile(const Value: Int64);
    function GetNewFileName: string;
  private
    FShuffle: boolean;
    FLast: boolean;
    FDone: Int64;
    FToDo: Int64;
    FTotal: Int64;
    FBackup: boolean;
    property MaxItemsPerFile: Int64 read FMaxItemsPerFile write SetMaxItemsPerFile default 0;
    procedure CreateDictionaryInit  (
                                      Directory, FileName: string;
                                      Callback: TCreateDictionaryCallback;
                                      MaxItems: Int64;
                                      Shuffle: boolean
                                    );
    function AddItem(Item: string): boolean;
  public
    constructor Create;
    destructor Destroy; override;
    property FileDirectory: string read GetDirectory write SetDirectory;
    property FileName: string read GetFileName;
    property TotalFiles: integer read GetTotalFiles default 0;
    property FilesToDo: integer read GetFilesToDo default 0;
    property FilesDone: integer read GetFilesDone default 0;
    procedure CreateDictionaryReset;
  end;

  TBruteForce = class(TCustomBruteForce)
  strict private
    FChars: string;
    FCharsLen: smallint;
    FMinLen: smallint;
    FMaxLen: smallint;
    FCounters: TArray<smallint>;
  private
    function GetMinLength: smallint; virtual;
    function GetMaxLength: smallint; virtual;
    function GetCharacters: string; virtual;
    function GetLast: boolean;
    function GetTotal: Int64;
    function GetDone: Int64;
    function GetToDo: Int64;
  public
    property Last: boolean read GetLast default false;
    property Total: Int64 read GetTotal default 0;
    property Done: Int64 read GetDone default 0;
    property ToDo: Int64 read GetToDo default 0;
    property Characters: string read GetCharacters;
    property MinLength: smallint read GetMinLength default 0;
    property MaxLength: smallint read GetMaxLength default 0;
    constructor Create (Characters: string; MinLength, MaxLength: TCredentialLength);
    destructor Destroy; override;
    function Next: string;
    procedure Reset; virtual;
    procedure CreateDictionary(
                                Directory, FileName: string;
                                CreateDictionaryCallback: TCreateDictionaryCallback = nil;
                                TaskFinishedCallBack: TThreadProcedure = nil;
                                MaxItems: Int64 = 0;
                                Shuffle: boolean = true;
                                Backup: boolean = false
                              );
  end;

  TBruteForceEx = class(TBruteForce)
  private
    FUsernameDic: TArray<string>;
    FPasswordDic: TArray<string>;
    FUsernameDicCount: Int64;
    FPasswordDicCount: Int64;
    BruteForce: TBruteForce;
    FUsernameDicLen: Int64;
    FPasswordDicLen: Int64;
    FSeparator: string;
    function GetMinLength: smallint; override;
    function GetMaxLength: smallint; override;
    function GetCharacters: string; override;
    procedure SetSeparator(Value: string);
  protected
    property FileItemSeparator: string read FSeparator write SetSeparator;
  public
    property UsernameDictionary: TArray<string> read FUsernameDic;
    property PasswordDictionary: TArray<string> read FPasswordDic;
    constructor Create  (
                          UsernameDictionary: TArray<string>;
                          PasswordDictionary: TArray<string> = nil;
                          Characters: string = '';
                          MinLength: TCredentialLength = 3;
                          MaxLength: TCredentialLength = 6
                        );
    destructor Destroy; override;
    function Next: TCredentials;
    procedure Reset; override;
    procedure CreateDictionary  (
                                  Directory, FileName: string;
                                  var Separator: string;
                                  Callback: TCreateDictionaryCallback = nil;
                                  TaskFinishedCallBack: TThreadProcedure = nil;
                                  MaxItems: Int64 = 0;
                                  Shuffle: boolean = true;
                                  Backup: boolean = false
                                );
  end;

  procedure LoadFileToStringList  (
                                    dlgOpenFile: TOpenDialog;
                                    AddListItemCallback: TBFAddListItemCallback;
                                    ProgressCallback: TBFProgressCallback = nil;
                                    TaskFinishedCallBack: TThreadProcedure = nil
                                  );

implementation

uses
  System.SysUtils
  , System.Math
  , System.StrUtils
  , System.IOUtils;

{$IFDEF VER230}
  {$DEFINE USE_TSEARCHREC_SIZE}
{$ELSE}
  {$IFNDEF MSWINDOWS}
    {$DEFINE USE_TSEARCHREC_SIZE}
  {$ENDIF}
{$ENDIF}

function GetFileSize(fileName: String): Int64;
var
  sr : TSearchRec;

begin

  if FindFirst(fileName, faAnyFile, sr ) = 0 then
  begin
    {$IFDEF USE_TSEARCHREC_SIZE}
    Result := sr.Size;
    {$ELSE}
    Result := (Int64(sr.FindData.nFileSizeHigh) shl 32) + sr.FindData.nFileSizeLow;
    {$ENDIF}
    FindClose(sr);
  end
  else
     Result := -1;

end;

procedure LoadFileToStringList  (
                                  dlgOpenFile: TOpenDialog;
                                  AddListItemCallback: TBFAddListItemCallback;
                                  ProgressCallback: TBFProgressCallback = nil;
                                  TaskFinishedCallBack: TThreadProcedure = nil
                                );
var
  Total, ToDo, Done: Int64;
  Reader: TextFile;
  Stop: boolean;
  FileName, Line: string;

begin

  try
    Stop := false;
    Total := 0;
    ToDo := 0;
    Done := 0;
    FileName := '';
    if dlgOpenFile.Execute then
      FileName := dlgOpenFile.FileName;
    if (not FileExists(FileName)) or (FileName = '') then
    begin
      if Assigned(ProgressCallback) then
      begin
        Stop := true;
        TThread.Synchronize (
                              TThread.CurrentThread,
                              procedure
                              begin
                                ProgressCallback(Total, Done, ToDo, Stop);
                              end
        );
      end;
      Exit;
    end;
    try
      Total := GetFileSize(FileName);
      ToDo := Total;
      if Total < 0 then
        raise Exception.Create('File not found')
      else
      begin
        AssignFile(Reader, FileName);
        Reset(Reader);
        try
          while (not Stop) and (not EOF(Reader)) do
          begin
            if Done >= MaxInt then
              raise Exception.Create(Format('Reached the maximum number (%d) of lines', [MaxInt]));
            Readln(Reader, Line);
            TThread.Synchronize (
                                  TThread.CurrentThread,
                                  procedure
                                  begin
                                    AddListItemCallback(Line);
                                  end
            );
            Done := Done + Length(Line) + 2;
            ToDo := ToDo - Length(Line) - 2;
            if Assigned(ProgressCallback) then
              TThread.Synchronize (
                                    TThread.CurrentThread,
                                    procedure
                                    begin
                                      ProgressCallback(Total, Done, ToDo, Stop);
                                    end
              );
          end;
        finally
          CloseFile(Reader);
        end;
        Stop := true;
        if Assigned(ProgressCallback) then
          TThread.Synchronize (
                                TThread.CurrentThread,
                                procedure
                                begin
                                  ProgressCallback(Total, Done, ToDo, Stop);
                                end
          );
      end;
    except
      on E: Exception do
      begin
        if Assigned(ProgressCallback) then
        begin
          Stop := true;
          TThread.Synchronize (
                                TThread.CurrentThread,
                                procedure
                                begin
                                  ProgressCallback(Total, Done, ToDo, Stop, E.Message);
                                end
          );
        end;
      end;
    end;
  finally
      if Assigned(TaskFinishedCallBack) then
        TThread.Synchronize(TThread.CurrentThread, TaskFinishedCallBack);
  end;

end;

procedure ClearDuplicateItems(var Items: TArray<string>; CaseSensitive: boolean = true); overload;
var
  i, x: Int64;
  Done: boolean;

begin

  i := 0;
  Done := false;

  while not Done do
  begin
    if i <= High(Items) then
    begin
      for x := High(Items) downto i + 1  do
        if CaseSensitive then
        begin
          if Items[x] = Items[i] then
            Delete(Items, x, 1);
        end
        else
          if UpperCase(Items[x]) = UpperCase(Items[i]) then
            Delete(Items, x, 1);
      i := i + 1;
    end
    else
      Done := true;
  end;

end;

procedure ClearDuplicateItems(var Items: string; CaseSensitive: boolean = true); overload;
var
  i, x: Int64;
  Done: boolean;

begin

  i := 1;
  Done := false;

  while not Done do
  begin
    if i <= Length(Items) then
    begin
      for x := Length(Items) downto i + 1  do
        if CaseSensitive then
        begin
          if Items[x] = Items[i] then
            Delete(Items, x, 1);
        end
        else
          if UpperCase(Items[x]) = UpperCase(Items[i]) then
            Delete(Items, x, 1);
      i := i + 1;
    end
    else
      Done := true;
  end;

end;


function ModInt64(Val1: Int64; Val2: Int64): Int64;
begin

  Result := 0;

  if (Val1 <= MaxInt) and (Val2 <= MaxInt) then
    exit(Val1 mod Val2);

  if (Val1 > 0) and (Val2 > 0) then
    Result := Abs(Val1 - (Trunc(Val1 / Val2) * Val2));

  if Result >= Val2 then
  begin
    if (Result <= MaxInt) and (Val2 <= MaxInt) then
      exit(Result mod Val2);
    Result := Val2 - 1;
  end;


end;

function RandU64: UInt64; { https://en.delphipraxis.net/topic/3739-random-unsigned-64-bit-integers/ }
begin

  Randomize;
  Result := UInt64(Random($10000));
  Result := (Result shl 16) or UInt64(Random($10000));
  Result := (Result shl 16) or UInt64(Random($10000));
  Result := (Result shl 16) or UInt64(Random($10000));

end;

procedure ShuffleItems  (
                          FileName: string;
                          NIntems: Int64;
                          Backup: boolean = false;
                          Callback: TCreateDictionaryCallback = nil;
                          FilesDone: Int64 = 0;
                          TotalFiles: Int64 = 0
                        );
var
  SourceStream: TFileStream;
  Writer: TStreamWriter;
  ShuffleFileName: String;
  ItemsToProcess, LineToProcess, LinePos: Int64;
  Character: char;
  Stop: boolean;

  procedure GoToLine(Dest: Int64);
  begin

    while LinePos <> Dest do
    begin
      if Dest < LinePos then
      begin
        SourceStream.Seek(0, TSeekOrigin.soBeginning);
        LinePos := 1;
        Continue;
      end;
      repeat
        SourceStream.Read(Character, 1);
      until (Character = #13) or (Character = #10);
      SourceStream.Read(Character, 1);
      if (Character <> #13) and (Character <> #10) then
        SourceStream.Seek(Length(Character) * (-1), TSeekOrigin.soCurrent);
      LinePos := LinePos + 1;
    end;

  end;

  function ChkCurrLineProcessed: boolean;
  begin

      SourceStream.Read(Character, 1);
      Result := Character = #9;
      SourceStream.Seek(-1, TSeekOrigin.soCurrent);

  end;

  function ReadLine: string;
  begin

      Result := '';
      SourceStream.Read(Character, 1);

      repeat
        Result := Result + Character;
        SourceStream.Read(Character, 1);
      until (Character = #13) or (Character = #10);

      SourceStream.Seek((Length(Result) * (-1)) - Length(Character), TSeekOrigin.soCurrent);
      Character := #9;
      SourceStream.Write(Character, 1);
      SourceStream.Seek(Length(Character) * (-1), TSeekOrigin.soCurrent);
      ItemsToProcess := ItemsToProcess - 1;

  end;

begin

  if Backup then
    TFile.Copy(FileName, FileName + '.bck', true);

  ShuffleFileName := IncludeTrailingPathDelimiter(TPath.GetDirectoryName(FileName))
                      + TPath.GetGUIDFileName() + '_'
                      + TPath.ChangeExtension(TPath.GetFileName(Filename), '.shuffle');
  SourceStream := TFileStream.Create(FileName, fmOpenReadWrite);
  Writer := TStreamWriter.Create(ShuffleFileName, false);

  try
    ItemsToProcess := NIntems;
    while ItemsToProcess > 0 do
    begin
      LineToProcess := ModInt64(Abs(RandU64), ItemsToProcess) + 1;
      SourceStream.Seek(0, TSeekOrigin.soBeginning);
      LinePos := 1;
      if not ChkCurrLineProcessed then
        LineToProcess := LineToProcess - 1;
      while LineToProcess > 0 do
      begin
        GoToLine(LinePos + 1);
        if not ChkCurrLineProcessed then
          LineToProcess := LineToProcess - 1;
      end;
      Writer.WriteLine(ReadLine);
      if Assigned(Callback) then
      begin
        Stop := false;
        TThread.Synchronize(
                        TThread.CurrentThread,
                        procedure
                        begin
                          Callback (
                                      NIntems,
                                      NIntems - ItemsToProcess,
                                      ItemsToProcess,
                                      TotalFiles,
                                      FilesDone,
                                      0,
                                      Stop
                                    );
                        end
        );
      end;
    end;
  finally
    SourceStream.Free;
    Writer.Free;
  end;

  TFile.Delete(FileName);
  TFile.Move(ShuffleFileName, FileName);

{ POSIX: trying to move a file may actually copy it if destination directory is
  a mount point for another partition. }
  if FileExists(ShuffleFileName) then
    TFile.Delete(FileName);

end;

{ TBruteForce }

constructor TBruteForce.Create(Characters: string; MinLength, MaxLength: TCredentialLength);
var
  I: smallint;

begin

  inherited Create;

  if Characters = '' then
    raise Exception.Create('Characters must be not empty');

  if MaxLength < MinLength then
    raise Exception.Create('MaxLength must be greater than or equal to MinLength');

  FChars := Characters;
  ClearDuplicateItems(FChars);
  FCharsLen := Length(FChars);
  FMinLen := MinLength;
  FMaxLen := MaxLength;
  FTotal := 0;

  for I := FMinLen to FMaxLen do
    FTotal := FTotal + Trunc(Power(FCharsLen, I));

  Reset;

end;

procedure TBruteForce.CreateDictionary  (
                                          Directory, FileName: string;
                                          CreateDictionaryCallback: TCreateDictionaryCallback = nil;
                                          TaskFinishedCallBack: TThreadProcedure = nil;
                                          MaxItems: Int64 = 0;
                                          Shuffle: boolean = true;
                                          Backup: boolean = false
                                        );
begin

  try
    FBackup := Backup;
    if (Shuffle <> FShuffle) or (MaxItems <> MaxItemsPerFile) then
      Reset;
    CreateDictionaryInit(Directory, FileName, CreateDictionaryCallback, MaxItems, Shuffle);
    while (not Last) and AddItem(Next) do
  finally
    if Assigned(TaskFinishedCallBack) then
      TThread.Synchronize(TThread.CurrentThread, TaskFinishedCallBack);
  end;

end;

destructor TBruteForce.Destroy;
begin

  inherited;
  SetLength(FCounters, 0);
  FCounters := nil;

end;

function TBruteForce.GetCharacters: string;
begin

  Result := FChars;

end;

function TBruteForce.GetDone: Int64;
begin

  Result := FDone;

end;

function TBruteForce.GetLast: boolean;
begin

  Result := FLast;

end;

function TBruteForce.GetMaxLength: smallint;
begin

  Result := FMaxLen;

end;

function TBruteForce.GetMinLength: smallint;
begin

  Result := FMinLen;

end;

function TBruteForce.GetToDo: Int64;
begin

  Result := FToDo;

end;

function TBruteForce.GetTotal: Int64;
begin

  Result := FTotal;

end;

function TBruteForce.Next: string;
var
  I, Len: smallint;
  Completed, Increment: boolean;

begin

  Result := '';

  if not FLast then
  begin
    Completed := false;
    Increment := false;
    Len := Length(FCounters);
    for I := Len - 1 downto 0 do
    begin
      Result := FChars[FCounters[I] + 1] + Result;
      if FCounters[I] < (FCharsLen - 1) then
      begin
        if not Increment then
        begin
          FCounters[I] := FCounters[I] + 1;
          Increment := true;
        end;
      end
      else
      begin
        if not Increment then
        begin
          FCounters[I] := 0;
          if I = 0 then
            Completed := true;
        end;
      end;
    end;
    if Completed then
    begin
      if Len = FMaxLen then
        FLast := true
      else
      begin
        SetLength(FCounters, Len + 1);
        FCounters[Len] := 0;
      end;
    end;
    FDone := FDone + 1;
    FToDo := FToDo - 1;
  end;

end;

procedure TBruteForce.Reset;
var
  I: smallint;

begin

  FLast := false;
  FDone := 0;
  SetLength(FCounters, FMinLen);

  for I := FMinLen - 1 downto 0 do
    FCounters[I] := 0;

  FToDo := FTotal;
  CreateDictionaryReset;

end;

{ TBruteForceEx }

constructor TBruteForceEx.Create  (
                                    UsernameDictionary, PasswordDictionary: TArray<string>;
                                    Characters: string;
                                    MinLength, MaxLength: TCredentialLength
                                  );
begin

  if (not Assigned(UsernameDictionary)) or (Length(UsernameDictionary) = 0) then
    raise Exception.Create('UsernameDictionary must be not empty');

  FUsernameDic := UsernameDictionary;
  ClearDuplicateItems(FUsernameDic, false);
  FUsernameDicLen := Length(FUsernameDic);

  if Characters <> '' then
  begin
    BruteForce := TBruteForce.Create(Characters, MinLength, MaxLength);
    FTotal := BruteForce.Total;
  end
  else
  begin
    BruteForce := nil;
    FTotal := 0;
    if (not Assigned(PasswordDictionary)) or (Length(PasswordDictionary) = 0) then
      raise Exception.Create('PasswordDictionary or Characters must be not empty');
  end;

  if Assigned(PasswordDictionary) then
  begin
    FPasswordDic := PasswordDictionary;
    ClearDuplicateItems(FPasswordDic);
    FPasswordDicLen := Length(FPasswordDic);
  end
  else
  begin
    FPasswordDic := nil;
    FPasswordDicLen := 0;
  end;

  FTotal := (FTotal + FPasswordDicLen) * FUsernameDicLen;
  Reset;

end;

procedure TBruteForceEx.CreateDictionary  (
                                            Directory, FileName: string;
                                            var Separator: string;
                                            Callback: TCreateDictionaryCallback = nil;
                                            TaskFinishedCallBack: TThreadProcedure = nil;
                                            MaxItems: Int64 = 0;
                                            Shuffle: boolean = true;
                                            Backup: boolean = false
                                          );
var
  GoOn: boolean;
  Credentials: TCredentials;

begin

  try
    FBackup := Backup;
    if (Shuffle <> FShuffle) or (MaxItems <> MaxItemsPerFile) then
      Reset;
    FileItemSeparator := Separator;
    CreateDictionaryInit(Directory, FileName, Callback, MaxItems, Shuffle);
    Separator := FileItemSeparator;
    GoOn := true;
    while (not Last) and GoOn do
    begin
      Credentials := Next;
      GoOn := AddItem(Credentials[0] + FileItemSeparator + Credentials[1]);
    end;
  finally
    if Assigned(TaskFinishedCallBack) then
      TThread.Synchronize(TThread.CurrentThread, TaskFinishedCallBack);
  end;

end;

destructor TBruteForceEx.Destroy;
begin

  inherited;

  SetLength(FUsernameDic, 0);
  FUsernameDic := nil;
  SetLength(FPasswordDic, 0);
  FPasswordDic := nil;


end;

function TBruteForceEx.GetCharacters: string;
begin

  if Assigned(Bruteforce) then
    Result := Bruteforce.Characters
  else
    Result := '';

end;

function TBruteForceEx.GetMaxLength: smallint;
begin

  if Assigned(Bruteforce) then
    Result := Bruteforce.MaxLength
  else
    Result := 0;

end;

function TBruteForceEx.GetMinLength: smallint;
begin

  if Assigned(Bruteforce) then
    Result := Bruteforce.MinLength
  else
    Result := 0;

end;

function TBruteForceEx.Next: TCredentials;
begin

  Result[0] := '';
  Result[1] := '';

  if not FLast then
  begin
    Result[0] := FUsernameDic[FUsernameDicCount];
    if FPasswordDicCount < FPasswordDicLen then
    begin
      Result[1] := FPasswordDic[FPasswordDicCount];
      FPasswordDicCount := FPasswordDicCount + 1;
      if FPasswordDicCount = FPasswordDicLen then
      begin
        if not Assigned(Bruteforce) then
        begin
          FUsernameDicCount := FUsernameDicCount + 1;
          if FUsernameDicCount = FUsernameDicLen then
            FLast := true
          else
            FPasswordDicCount := 0;
        end;
      end;
    end
    else
    begin
      Result[1] := Bruteforce.Next;
      if Bruteforce.Last then
      begin
          FUsernameDicCount := FUsernameDicCount + 1;
          if FUsernameDicCount = FUsernameDicLen then
            FLast := true
          else
          begin
            Bruteforce.Reset;
            FPasswordDicCount := 0;
          end;
      end;
    end;
    FDone := FDone + 1;
    FToDo := FToDo - 1;
  end;

end;

procedure TBruteForceEx.Reset;
begin

  FLast := false;
  FDone := 0;
  FToDo := FTotal;
  FUsernameDicCount := 0;
  FPasswordDicCount := 0;

  if Assigned(BruteForce) then
    BruteForce.Reset;

  CreateDictionaryReset;

end;

procedure TBruteForceEx.SetSeparator(Value: string);
begin

  if Value = '' then
    Value := #9;

  if Value <> FSeparator then
    FSeparator := Value;

end;

{ TCustomBruteForce }

function TCustomBruteForce.AddItem(Item: string): boolean;
var
  FilePathName: string;
  Stop: boolean;

begin

{$I-}

  Stop := false;

  try
    FilePathName := FileDirectory + GetNewFileName;
    if (FFileItems = 0) or ((MaxItemsPerFile > 0) and (FFileItems >= MaxItemsPerFile)) then
    begin
      CloseFile(FFileHandler);
      TThread.Sleep(1000);
      AssignFile(FFileHandler, FilePathName);
      ReWrite(FFileHandler);
      IOResult;
      FFileItems := 0;
      TThread.Sleep(1000);
    end;
      Writeln(FFileHandler, Item);
    FFileItems := FFileItems + 1;
    if FLast or ((MaxItemsPerFile > 0) and (FFileItems >= MaxItemsPerFile)) then
    begin
      CloseFile(FFileHandler);
      TThread.Sleep(1000);
      if FShuffle then
      begin
        if Assigned(FCallback) then
          TThread.Synchronize(
                          TThread.CurrentThread,
                          procedure
                          begin
                            FCallback (
                                        FTotal,
                                        FDone,
                                        FToDo,
                                        TotalFiles,
                                        FilesDone,
                                        FilesToDo,
                                        Stop,
                                        '',
                                        'Starting to shuffle the file ' + FilePathName + '...'
                                      );
                          end
          );
        ShuffleItems(FilePathName, FFileItems, FBackup, FCallback, FilesDone, TotalFiles);
        if Assigned(FCallback) then
          TThread.Synchronize(
                          TThread.CurrentThread,
                          procedure
                          begin
                            FCallback (
                                        FTotal,
                                        FDone,
                                        FToDo,
                                        TotalFiles,
                                        FilesDone,
                                        FilesToDo,
                                        Stop,
                                        '',
                                        'Shuffling of the file ' + FilePathName + ' completed'
                                      );
                          end
          );
      end;
      FFilesToDo := FFilesToDo - 1;
      FFilesDone := FFilesDone + 1;
    end;
    Stop := Stop or FLast;
    if Stop then
    begin
      CloseFile(FFileHandler);
      TThread.Sleep(1000);
    end;
    if Assigned(FCallback) then
      TThread.Synchronize(
                      TThread.CurrentThread,
                      procedure
                      begin
                        FCallback(FTotal, FDone, FToDo, TotalFiles, FilesDone, FilesToDo, Stop);
                      end
      );
    Result := not Stop;
  except
    on E: Exception do
    begin
      Result := false;
      if Assigned(FCallback) then
        TThread.Synchronize(
                        TThread.CurrentThread,
                        procedure
                        begin
                          FCallback(FTotal, FDone, FToDo, TotalFiles, FilesDone, FilesToDo, Stop, E.Message);
                        end
        );
    end;
  end;

end;

constructor TCustomBruteForce.Create;
begin

  inherited Create;
  CreateDictionaryReset;
  FBackup := false;

end;

procedure TCustomBruteForce.CreateDictionaryInit  (
                                                    Directory, FileName: string;
                                                    Callback: TCreateDictionaryCallback;
                                                    MaxItems: Int64;
                                                    Shuffle: boolean
                                                  );
begin

  SetDirectory(Directory);
  MaxItemsPerFile := MaxItems;
  FFileName := FileName;
  FCallback := Callback;
  FShuffle := Shuffle;

end;

procedure TCustomBruteForce.CreateDictionaryReset;
begin

  FFileName := '';
  FShuffle := true;
  FMaxItemsPerFile := 0;
  FTotalFiles := 0;
  FFilesToDo := 0;
  FFilesDone := 0;
  FCallback := nil;
  FFileIndexDigits := 0;
  FFileItems := 0;

{$I-}

  CloseFile(FFileHandler);

end;

destructor TCustomBruteForce.Destroy;
begin

  inherited;


{$I-}

  CloseFile(FFileHandler);

end;

function TCustomBruteForce.GetDirectory: string;
begin

  Result := FDirectory;

end;

function TCustomBruteForce.GetFileName: string;
begin

  Result := FFileName;

end;

function TCustomBruteForce.GetFilesDone: integer;
begin

  Result := FFilesDone;

end;

function TCustomBruteForce.GetFilesToDo: integer;
begin

  Result := FFilesToDo;

end;

function TCustomBruteForce.GetNewFileName: string;
var
  FileExt: string;

begin

  Result := FFileName;

  if FTotalFiles > 1 then
  begin
    FileExt := TPath.GetExtension(Result);
    Result := TPath.GetFileNameWithoutExtension(Result);
    Result := Format('%s_%.*d', [Result, FFileIndexDigits, FFilesDone]) + FileExt;
  end;

end;

function TCustomBruteForce.GetTotalFiles: integer;
begin

  Result := FTotalFiles

end;

procedure TCustomBruteForce.SetDirectory(Value: string);
begin

  if (Value <> '') and (not DirectoryExists(Value)) then
    raise Exception.Create('Directory not found');

  Value := IncludeTrailingPathDelimiter(Value);

  if Value <> FDirectory then
    FDirectory := Value;

end;

procedure TCustomBruteForce.SetMaxItemsPerFile(const Value: Int64);
begin

  CreateDictionaryReset;

  if FTotal > 0 then
    FTotalFiles := 1;

  FMaxItemsPerFile := Value;

  if (FMaxItemsPerFile > 0) and (FTotal > 0) then
  begin
    FTotalFiles := Trunc(FTotal / FMaxItemsPerFile);
    if (FTotal mod FMaxItemsPerFile) <> 0 then
      FTotalFiles := FTotalFiles + 1;
    FFileIndexDigits := Length(IntToStr(FTotalFiles - 1));
  end;

  FFilesToDo := FTotalFiles;

end;

end.
