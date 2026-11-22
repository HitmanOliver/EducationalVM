program EduVM;
{$H+}
{$I-}
uses StackAndQueue;

const
    MemorySize = 65535; 
   
    commandsCount = 4;
    tokensCountInCommand = 2;

    PushConstComm = 'push';
    PushVarByAddrFromStackComm = 'lods';
    PutStackVarByAddrComm = 'stos';
    XorFromStackVarsComm = 'xor';
    
    NoParamsErr = 'Error: Specify the text file and the output file';
    NoOutputFileErr = 'Error: Specify the output file';
    OpenFileErrorMsg = 'Error: Could not open the file';
    UnknownParamErr =  'Error: Unknown param';
    NoTestModeParam = 'Error: program requires "test" param"';   
    WrongCommandErr = 'Error: wrong command';
    NoOperandErr = 'Error: command requires an operand';
    WrongOperandErr = 'Error: operand type is not eligible';
    UnexpectedOperandErr = 'Error: No operand requires by command';
    TooMuchOperandsErr = 'Error: command requires only one operand';
    UnexpectedSymb = 'Error: unexpected symbol';

    SpaceCharCode = 32;
    TabCharCode = 9;
    EnterCharCode = 10;
    
type
    EduVmCommand = record
        name: string;
        opcode: Byte;
        size: Byte;
        hadOperand: Boolean;
    end;
    EduVmCommandsArr = array [1..commandsCount] of EduVmCommand;
    TMemory = array [0..MemorySize] of LongWord;

    BinaryFile = file of Byte;

const
    VM_COMMANDS_MANUAL: EduVmCommandsArr = (
        (name: PushConstComm; opcode: 6; size: 4; hadOperand: True),
        (name: PushVarByAddrFromStackComm; opcode: 3; size: 1; hadOperand: False),
        (name: PutStackVarByAddrComm; opcode: 1; size: 3; hadOperand: True),
        (name: XorFromStackVarsComm; opcode: 4; size: 2; hadOperand: True)
        );


function FindCommandInManual(command: string; var manual: EduVmCommand): Boolean;
var
    i: integer;
begin
    for i := 1 to commandsCount do
        if (command = VM_COMMANDS_MANUAL[i].name) then
        begin
            manual := VM_COMMANDS_MANUAL[i];
            FindCommandInManual := True;
            exit
        end;
    FindCommandInManual := false
end;

function IsCharLatin(c: char): Boolean;
begin
    IsCharLatin := ((c >= #65) and (c <= #90)) or ((c >= #97) and (c <= #122))
end;

function IsCharDigit(c: char): Boolean;
begin
    IsCharDigit := (c >= #48) and (c <= #57)
end;

procedure ParseCommandAndOperand(var line, command, operand: string; 
                                CurrLineNum: integer
                                ); 
var
    c: char;
    token: string;
    tokensCount: integer;
    currPos: integer;
begin
    command := '';
    operand := '';
    token := '';
    tokensCount := 0;
    for currPos := 1 to Length(line) do
    begin
        c := line[currPos];
        if IsCharLatin(c) or IsCharDigit(c) then 
            token := token + c
        else if (Ord(c) = TabCharCode) or (Ord(c) = SpaceCharCode) then
        begin
            if token = '' then continue;
            tokensCount := tokensCount + 1;
            if tokensCount > tokensCountInCommand then
            begin
                writeln(TooMuchOperandsErr, ' in line ', CurrLineNum);
                halt(1)
            end else if tokensCount = 1 then 
                command := token
            else 
                operand := token;
            token := '';
        end else
        begin
            writeln(UnexpectedSymb, ' "', c, '" in line ', CurrLineNum);
            halt(1)
        end
    end;

    if token <> '' then
    begin
        tokensCount := tokensCount + 1;
        if tokensCount > tokensCountInCommand then
        begin
            writeln(TooMuchOperandsErr, ' in line ', CurrLineNum);
            halt(1)
        end else if tokensCount = 1 then
            command := token
        else
            operand := token
    end
end;

procedure CheckCommandAndOperand(var command, operand: string; 
                                var operandNum: LongWord;
                                var manual: EduVmCommand;
                                CurrLineNum: integer);
var
    err: integer;
begin
    operandNum := 0;
    if not FindCommandInManual(command, manual) then
    begin
        writeln(WrongCommandErr, ' "', command, '" in line ', CurrLineNum);
        halt(1)
    end else begin
        if manual.hadOperand then
        begin
            if operand = '' then
            begin
                writeln(NoOperandErr, ' "', command, '" in line ', CurrLineNum);
                halt(1)
            end;
            Val(operand, operandNum, err);
            if err <> 0 then
            begin
                writeln(WrongOperandErr, ' in line ', CurrLineNum);
                halt(1)
            end
        end else begin
            if operand <> '' then
            begin
                writeln(UnexpectedOperandErr, ' "', command, 
                        '" in line ', CurrLineNum);
                halt(1)
            end
        end
    end
end;

procedure LoadAsmCommand(var queue: TInstructionsQueue; var f: Textfile);
var
    line, command, operand: string;
    operandNum: LongWord;
    CurrLineNum: integer;
    VMInstruction: TAbstractMachineComm;
    manual: EduVmCommand;
begin
    CurrLineNum := 0;
    while not Eof(f) do
    begin
        readln(f, line);
        CurrLineNum := CurrLineNum + 1;
        ParseCommandAndOperand(line, command, operand, CurrLineNum);
        if command = '' then continue;
        CheckCommandAndOperand(command, operand, operandNum, manual, CurrLineNum);
        VMInstruction.opcode := manual.opcode;
        VMInstruction.operand := operandNum;
        VMInstruction.size := manual.size;
        PushInsQueueElem(queue, VMInstruction)
    end
end;

procedure CheckStdinParams();
begin
    if (ParamCount < 1) then
    begin  
        writeln(NoParamsErr);
        halt(1)
    end;
    if (ParamCount < 2) then
    begin 
        writeln(NoOutputFileErr);
        halt(1)
    end;
    if (ParamCount < 3) then
    begin
        writeln(NoTestModeParam);
        halt(1)
    end;
    if (ParamStr(3) <> 'test') then
    begin
        writeln(UnknownParamErr + 
                ' "' + ParamStr(3) + '". ' +
                'Did you mean "test"?');
        halt(1)
    end;
end;

procedure AssignIOFiles(var AsmFile: Textfile; var OutputFile: BinaryFile);
begin
    assign(AsmFile, ParamStr(1));
    reset(AsmFile);
    if IOResult <> 0 then
    begin
        writeln(OpenFileErrorMsg + ' "' + ParamStr(1) + '"');
        halt(1)
    end;
    assign(OutputFile, ParamStr(2));
    rewrite(OutputFile);
    if IOResult <> 0 then
    begin
        writeln(OpenFileErrorMsg + ' "' + ParamStr(2) + '"');
        halt(1)
    end;
end;

{Only for first step}
procedure PrintInsideStructureOfCode(var queue: TInstructionsQueue);
var
    command: TAbstractMachineComm;
    tmp: TQueueElemPtr;
begin
    tmp := queue.first;
    while tmp <> nil do
    begin
        command := tmp^.command;
        writeln('(A=',command.opcode,',B=',command.operand,') size=',
                command.size,' Bytes');
        tmp := tmp^.nextComm
    end
end;

var
    AsmFile: Textfile;    
    OutputFile: BinaryFile;
    insQueue: TInstructionsQueue;
    programStack: TProgramStack;
begin
    CheckStdinParams;
    AssignIOFiles(AsmFile, OutputFile);
    InsQueueInit(insQueue);
    LoadAsmCommand(insQueue, AsmFile);
    close(AsmFile);
    close(OutputFile);
    PrintInsideStructureOfCode(insQueue)
end.
