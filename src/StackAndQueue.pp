unit StackAndQueue;

interface

type
    TAbstractMachineComm = record
        opcode: Byte;
        operand: LongWord;
        size: Byte;
    end; 

    TStackElemPtr = ^TStackElem;
    TStackElem = record
        value: LongWord;
        nextValue: TStackElemPtr;
    end;
    TProgramStack = record
        stackTop: TStackElemPtr;
    end;

    TQueueElemPtr = ^TQueueElem;
    TQueueElem = record
        command: TAbstractMachineComm;
        nextComm: TQueueElemPtr;
    end;
    TInstructionsQueue = record
        first: TQueueElemPtr;
        last: TQueueElemPtr;
    end;

procedure InsQueueInit(var queue: TInstructionsQueue);
procedure PushInsQueueElem(var queue: TInstructionsQueue; 
                          command: TAbstractMachineComm
                          );
procedure PopInsQueueElem(var queue: TInstructionsQueue;
                         var command: TAbstractMachineComm
                         );
procedure ProgramStackInit(var stack: TProgramStack);
procedure PushStack(var stack: TProgramStack; value: LongWord);
procedure PopStack(var stack: TProgramStack; var value: LongWord);

implementation

procedure InsQueueInit(var queue: TInstructionsQueue);
begin 
    queue.first := nil;
    queue.last := nil;
end;

procedure PushInsQueueElem(var queue: TInstructionsQueue; 
                          command: TAbstractMachineComm
                          );
begin
    if (queue.first = nil) then
    begin
        new(queue.first);
        queue.first^.command := command;
        queue.first^.nextComm := nil;
        queue.last := queue.first
    end else
    begin
        new(queue.last^.nextComm); 
        queue.last^.nextComm^.command := command;
        queue.last^.nextComm^.command := command;
        queue.last^.nextComm^.nextComm := nil;
        queue.last := queue.last^.nextComm;
    end
end;

procedure PopInsQueueElem(var queue: TInstructionsQueue;
                         var command: TAbstractMachineComm
                         );
var
    tmp: TQueueElemPtr;
begin
    if (queue.first = nil) then 
    begin
        queue.last := nil;
        command.opcode := 0; 
        exit 
    end;
    tmp := queue.first; 
    queue.first := queue.first^.nextComm;  
    command.opcode := tmp^.command.opcode; 
    command.operand := tmp^.command.operand; 
    command.size := tmp^.command.size; 
    dispose(tmp);
end;

procedure ProgramStackInit(var stack: TProgramStack);
begin
    stack.stackTop := nil;
end;

procedure PushStack(var stack: TProgramStack; value: LongWord);
var
    tmp: TStackElemPtr;
begin
    tmp := stack.stackTop;
    new(stack.stackTop);
    stack.stackTop^.value := value;
    stack.stackTop^.nextValue := tmp;
end;

procedure PopStack(var stack: TProgramStack; var value: LongWord);
var
    tmp: TStackElemPtr;
begin
    tmp := stack.stackTop;
    stack.stackTop := stack.stackTop^.nextValue;
    value := tmp^.value;
    dispose(tmp)
end;

end.

