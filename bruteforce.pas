unit bruteforce;

interface

uses
  System.Classes;

type

  TCredentials = Array[0..1] Of string;
  TCredentialLength = 1..512;
  TCreateDictionaryCallback = procedure (
                                          Total, Done, ToDo: Int64;
                                          TotalFiles, FilesDone, FilesToDo: integer;
                                          var Stop: boolean;
                                          ErrMsg: string = ''
                                        ) of object;

  TCustomBruteForce = class
  private
    FFileItems: Int64;
    FFileHandler: TextFile;
    FDirectory: string;
    FFileName: string;
    FShuffle: boolean;
    FMaxItemsPerFile: Int64;
    FTotalFiles: integer;
    FFilesToDo: integer;
    FFilesDone: integer;
    FCallback: TCreateDictionaryCallback;
    FFileIndexDigits: smallint;
    procedure SetDirectory(Value: string);
    procedure SetMaxItemsPerFile(const Value: Int64);
    function GetNewFileName: string;
  protected
    FLast: boolean;
    FDone: Int64;
    FToDo: Int64;
    FTotal: Int64;
    property MaxItemsPerFile: Int64 read FMaxItemsPerFile write SetMaxItemsPerFile default 0;
    procedure CreateDictionaryInit  (
                                      Directory, FileName: string;
                                      Callback: TCreateDictionaryCallback;
                                      MaxItems: Int64;
                                      Shuffle: boolean
                                    );
    function AddItem(const Item: string): boolean;
  public
    constructor Create;
    destructor Destroy; override;
    property FileDirectory: string read FDirectory;
    property FileName: string read FFileName;
    property TotalFiles: integer read FTotalFiles default 1;
    property FilesToDo: integer read FFilesToDo default 0;
    property FilesDone: integer read FFilesDone default 0;
    property MaxFileItems: Int64 read FMaxItemsPerFile default 0;
    procedure CreateDictionaryReset;
  end;

  TBruteForce = class(TCustomBruteForce)
  private
    FChars: string;
    FCharsLen: smallint;
    FMinLen: smallint;
    FMaxLen: smallint;
    FCounters: TArray<smallint>;
  public
    property Last: boolean read FLast default false;
    property Total: Int64 read FTotal default 0;
    property Done: Int64 read FDone default 0;
    property ToDo: Int64 read FToDo default 0;
    property Characters: string read FChars;
    property MinLength: smallint read FMinLen default 0;
    property MaxLength: smallint read FMaxLen default 0;
    constructor Create (Characters: string; MinLength, MaxLength: TCredentialLength);
    destructor Destroy; override;
    function Next: string;
    procedure Reset;
    procedure CreateDictionary(
                                Directory, FileName: string;
                                Callback: TCreateDictionaryCallback = nil;
                                TaskFinishedCallBack: TThreadProcedure = nil;
                                MaxItems: Int64 = 0;
                                Shuffle: boolean = true
                              );
  end;

  TBruteForceEx = class(TCustomBruteForce)
  private
    FUsernameDic: TArray<string>;
    FPasswordDic: TArray<string>;
    FChars: string;
    FMinLen: smallint;
    FMaxLen: smallint;
    FUsernameDicCount: Int64;
    FPasswordDicCount: Int64;
    BruteForce: TBruteForce;
    FUsernameDicLen: Int64;
    FPasswordDicLen: Int64;
    FSeparator: string;
    procedure SetSeparator(Value: string);
  protected
    property FileItemSeparator: string read FSeparator write SetSeparator;
  public
    property Last: boolean read FLast default false;
    property Total: Int64 read FTotal default 0;
    property Done: Int64 read FDone default 0;
    property ToDo: Int64 read FToDo default 0;
    property Characters: string read FChars;
    property MinLength: smallint read FMinLen default 0;
    property MaxLength: smallint read FMaxLen default 0;
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
    procedure Reset;
    procedure CreateDictionary  (
                                  Directory, FileName: string;
                                  var Separator: string;
                                  Callback: TCreateDictionaryCallback = nil;
                                  TaskFinishedCallBack: TThreadProcedure = nil;
                                  MaxItems: Int64 = 0;
                                  Shuffle: boolean = true
                                );
  end;

implementation

uses
  System.SysUtils
  , System.Math
  , System.StrUtils;

function RandU64: UInt64; { https://en.delphipraxis.net/topic/3739-random-unsigned-64-bit-integers/ }
begin

  Randomize;
  Result := UInt64(Random($10000));
  Result := (Result shl 16) or UInt64(Random($10000));
  Result := (Result shl 16) or UInt64(Random($10000));
  Result := (Result shl 16) or UInt64(Random($10000));

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
                                          Callback: TCreateDictionaryCallback = nil;
                                          TaskFinishedCallBack: TThreadProcedure = nil;
                                          MaxItems: Int64 = 0;
                                          Shuffle: boolean = true
                                        );
begin

  try
    CreateDictionaryInit(Directory, FileName, Callback, MaxItems, Shuffle);
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

  inherited Create;

  if (not Assigned(UsernameDictionary)) or (Length(UsernameDictionary) = 0) then
    raise Exception.Create('UsernameDictionary must be not empty');

  FUsernameDic := UsernameDictionary;
  FUsernameDicLen := Length(FUsernameDic);
  FChars :=  Characters;
  FMinLen := MinLength;
  FMaxLen := MaxLength;

  if FChars <> '' then
  begin
    BruteForce := TBruteForce.Create(FChars, FMinLen, FMaxLen);
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
                                            Shuffle: boolean = true
                                          );
var
  GoOn: boolean;
  Credentials: TCredentials;

begin

  try
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

function TCustomBruteForce.AddItem(const Item: string): boolean;
var
  FilePathName, Line: string;
  Stop: boolean;
  Index: Int64;

begin

{$I-}

  try
    if (FFilesDone = 0) or ((MaxItemsPerFile > 0) and (FFileItems >= MaxItemsPerFile)) then
    begin
      CloseFile(FFileHandler);
      FilePathName := FileDirectory + GetNewFileName;
      AssignFile(FFileHandler, FilePathName);
      ReWrite(FFileHandler);
      FFileItems := 0;
      Index := -1
    end
    else
    begin
      if FShuffle then
      begin
        Randomize;
        Index := (Abs(RandU64) mod FFileItems);
      end
      else
        Index := -1;
    end;
    while (not EOF(FFileHandler)) and (Index <> 0) do
      Readln(FFileHandler, Line);
    Writeln(FFileHandler, Item);
    FFileItems := FFileItems + 1;
    if FLast or ((MaxItemsPerFile > 0) and (FFileItems >= MaxItemsPerFile)) then
    begin
      CloseFile(FFileHandler);
      FFilesToDo := FFilesToDo - 1;
      FFilesDone := FFilesDone + 1;
    end;
    Stop := FLast;
    TThread.Synchronize(
                    TThread.CurrentThread,
                    procedure
                    begin
                      FCallback(FTotal, FDone, FToDo, TotalFiles, FilesDone, FilesToDo, Stop);
                    end
    );
    Result := not Stop;
    if (not Result) or FLast then
      CloseFile(FFileHandler);
  except
    on E: Exception do
    begin
      Result := false;
      CloseFile(FFileHandler);
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
  FShuffle := Shuffle;
  FCallback := Callback;

end;

procedure TCustomBruteForce.CreateDictionaryReset;
begin

  self.FDirectory := '';
  FFileName := '';
  FShuffle := true;
  FMaxItemsPerFile := 0;
  FTotalFiles := 1;
  FFilesToDo := 1;
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

function TCustomBruteForce.GetNewFileName: string;
begin

  Result := FFileName;

  if FTotalFiles > 1 then
    Result := Format('%s_%.*d', [Result, FFileIndexDigits, FFilesDone]);

end;

procedure TCustomBruteForce.SetDirectory(Value: string);
begin

  if not DirectoryExists(Value) then
    raise Exception.Create('Directory not found');

  Value := IncludeTrailingPathDelimiter(Value);

  if Value <> FDirectory then
    FDirectory := Value;

end;

procedure TCustomBruteForce.SetMaxItemsPerFile(const Value: Int64);
begin

  if Value <> FMaxItemsPerFile then
  begin
    FMaxItemsPerFile := Value;
    CreateDictionaryReset;
    if FMaxItemsPerFile > 0 then
    begin
      FTotalFiles := Trunc(FTotal / FMaxItemsPerFile);
      if (FTotal mod FMaxItemsPerFile) <> 0 then
        FTotalFiles := FTotalFiles + 1;
      FFileIndexDigits := Length(IntToStr(FTotalFiles));
    end;
    FFilesToDo := FTotalFiles;
  end;

end;

end.
