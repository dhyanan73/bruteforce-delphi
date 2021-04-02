unit bruteforce;

interface

type

  TCredentials = Array[0..1] Of string;
  TCredentialLength = 1..512;

  TBruteForce = class
  private
    FLast: boolean;
    FTotal: Int64;
    FDone: Int64;
    FToDo: Int64;
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
  end;

  TBruteForceEx = class
  private
    FLast: boolean;
    FTotal: Int64;
    FDone: Int64;
    FToDo: Int64;
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
  end;

procedure CreateDictionary(FilePath: string; BruteForce: TBruteForce; MaxItems: Int64 = 0; Shuffle: boolean = true);

implementation

uses
  System.SysUtils
  , System.Math;


procedure CreateDictionary(FilePath: string; BruteForce: TBruteForce; MaxItems: Int64 = 0; Shuffle: boolean = true);
begin


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
    raise Exception.Create('PasswordDictionary  must be not empty');

  FUsernameDic := UsernameDictionary;
  FUsernameDicLen := Length(FUsernameDic);
  FChars :=  Characters;
  FMinLen := MinLength;
  FMaxLen := MaxLength;

  if FChars <> '' then
  begin
    BruteForce := BruteForce.Create(FChars, FMinLen, FMaxLen);
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

end;

end.
