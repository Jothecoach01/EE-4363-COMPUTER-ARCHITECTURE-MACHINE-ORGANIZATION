// Incomplete behavioral model of MIPS pipeline

module mipspipe_mp3  (clock);
  // in_out
input clock;

  // Instruction opcodes
parameter LW = 6'b100011, SW = 6'b101011, BEQ=6'b000100, nop = 32'b00000_100000, ALUop=6'b0;

 reg[31:0] PC, Regs[0:31], IMemory[0:1023], DMemory[0:1023], // separate memories
 					                    // instruction and data memories
IFIDIR, IDEXA, IDEXB, IDEXIR, EXMEMIR, EXMEMB, // pipeline registers// pipeline latches
 EXMEMALUOut, MEMWBValue, MEMWBIR; // pipeline registers// pipeline latches


 wire [4:0] IDEXrs, IDEXrt, EXMEMrd, MEMWBrd, MEMWBrt; //hold register fields
 wire [5:0] EXMEMop, MEMWBop, IDEXop; //Hold opcodes
 wire [31:0] Ain, Bin;

// declare the bypass signals// wire stall IS ADDED
 wire stall, bypassAfromMEM, bypassAfromALUinWB,bypassBfromMEM, bypassBfromALUinWB,
 bypassAfromLWinWB, bypassBfromLWinWB;


 // Define fields of pipeline latches
   assign IDEXrs = IDEXIR[25:21]; // rs field
   assign IDEXrt = IDEXIR[20:16]; // rt field
   assign EXMEMrd = EXMEMIR[15:11]; // rd field
   assign MEMWBrd = MEMWBIR[15:11]; // rd field
   assign MEMWBrt = MEMWBIR[20:16]; // rt field -- for loads
   assign EXMEMop = EXMEMIR[31:26]; // opcode
   assign MEMWBop = MEMWBIR[31:26]; // opcode
   assign IDEXop = IDEXIR[31:26]; // opcode
  



 // The bypass to input A from the MEM stage for an ALU operation
 assign bypassAfromMEM = (IDEXrs == EXMEMrd) & (IDEXrs!=0) & (EXMEMop==ALUop); // yes, bypass

 // The bypass to input Bfrom the MEM stage for an ALU operation
 assign bypassBfromMEM = (IDEXrt== EXMEMrd)&(IDEXrt!=0) & (EXMEMop==ALUop); // yes, bypass

 // The bypass to input A from the WB stage for an ALU operation
 assign bypassAfromALUinWB =( IDEXrs == MEMWBrd) & (IDEXrs!=0) & (MEMWBop==ALUop);

 // The bypass to input B from the WB stage for an ALU operation
 assign bypassBfromALUinWB = (IDEXrt==MEMWBrd) & (IDEXrt!=0) & (MEMWBop==ALUop); 
 // The bypass to input A from the WB stage for an LW operation
 assign bypassAfromLWinWB =( IDEXrs ==MEMWBIR[20:16]) & (IDEXrs!=0) & (MEMWBop==LW);
 // The bypass to input B from the WB stage for an LW operation
 assign bypassBfromLWinWB = (IDEXrt==MEMWBIR[20:16]) & (IDEXrt!=0) & (MEMWBop==LW);



 // The A input to the ALU is bypassed from MEM if there is a bypass there,
 // Otherwise from WB if there is a bypass there, and otherwise comes from the IDEX register

 assign Ain = bypassAfromMEM? EXMEMALUOut :
 (bypassAfromALUinWB | bypassAfromLWinWB)? MEMWBValue : IDEXA;
 
// The B input to the ALU is bypassed from MEM if there is a bypass there,
 // Otherwise from WB if there is a bypass there, and otherwise comes from the IDEX register
 assign Bin = bypassBfromMEM? EXMEMALUOut :
 (bypassBfromALUinWB | bypassBfromLWinWB)? MEMWBValue: IDEXB;

// The signal for detecting a stall based on the use of a result from LW
 assign stall = (MEMWBIR[31:26]==LW) && // source instruction is a load
 ((((IDEXop==LW)|(IDEXop==SW)) && (IDEXrs==MEMWBrd)) | // stall for address calc
((IDEXop==ALUop) && ((IDEXrs==MEMWBrd)|(IDEXrt==MEMWBrd)))); // ALU use


  reg [5:0] i;//,j,k; //used to initialize registers
 reg [10:0] j,k; // used to initialize memories
 


 initial begin
 PC = 0;
 IFIDIR=nop; 
 IDEXIR=nop; 
 EXMEMIR=nop;
 MEMWBIR=nop; // put no-ops in pipeline registers

   for (i = 0;i<=31;i = i+1) Regs[i] = i; // initialize latches
  
    IMemory[0] = 32'h00412820;
    IMemory[1] = 32'h8ca30004;
    IMemory[2] = 32'haca70005;
    IMemory[3] = 32'h00602020;
    IMemory[4] = 32'h01093020;
    IMemory[5] = 32'hac06000c;  
    IMemory[6] = 32'h00c05020;
    IMemory[7] = 32'h8c0b0010;
    IMemory[8] = 32'h00000020;  
    IMemory[9] = 32'h002b6020;
    for (j=10; j<=1023; j=j+1) IMemory[j] = nop;
    
    DMemory[0] = 32'h00000000;
    DMemory[1] = 32'hffffffff;
    DMemory[2] = 32'h00000000;
    DMemory[3] = 32'h00000000;
    DMemory[4] = 32'hfffffffe;
    for (k=5; k<=1023; k=k+1) DMemory[k] = 0;
  end

//for (i=0;i<=31;i=i+1) Regs[i] = i; //initialize registers--just so they aren’t cares
// end

 always @ (posedge clock) 
 begin



	// FETCH: Fetch instruction & update PC
 if (~stall) begin // the first three pipeline stages stall if there is a load hazard

 // first instruction in the pipeline is being fetched
 IFIDIR <= IMemory[PC>>2];
 PC <= PC + 4;


    // DECODE: Read registers
 //IDEXA <= Regs[IFIDIR[25:21]]; 
 //IDEXB <= Regs[IFIDIR[20:16]];
 IDEXIR <= IFIDIR; //pass along IR--come happen anywhere, since this affects next stage only!

 // second instruction is in register fetch
 IDEXA <= Regs[IFIDIR[25:21]]; IDEXB <= Regs[IFIDIR[20:16]]; // get two registers

 // third instruction is doing address calculation or ALU operation
 if ((IDEXop==LW) |(IDEXop==SW)) // address calculation & copy B
 	EXMEMALUOut <= IDEXA +{{16{IDEXIR[15]}}, IDEXIR[15:0]};
 else if (IDEXop==ALUop)
 	case (IDEXIR[5:0]) //case for the various R-type instructions
 	 	32: EXMEMALUOut <= Ain + Bin; //add operation
 		default: ; //other R-type operations: subtract, SLT, etc.
 	endcase
 EXMEMIR <= IDEXIR;
 EXMEMB <= IDEXB; //pass along the IR & B register
 end
 else EXMEMIR <= nop; //Freeze first three stages of pipeline; inject a nop into the EX output

 //Mem stage of pipeline
 if (EXMEMop==ALUop) MEMWBValue <= EXMEMALUOut; //pass along ALU result
 else if (EXMEMop == LW) MEMWBValue <= DMemory[EXMEMALUOut>>2];
 else if (EXMEMop == SW) DMemory[EXMEMALUOut>>2] <=EXMEMB; //store
 
MEMWBIR <= EXMEMIR; //pass along IR

 // the WB stage
 if ((MEMWBop==ALUop) & (MEMWBrd != 0)) // update latches if ALU operation and destination not 0
 Regs[MEMWBrd] <= MEMWBValue; // ALU operation
 else if ((EXMEMop == LW)& (MEMWBrt != 0)) // Update latches if load and destination not 0
 Regs[MEMWBrt] <= MEMWBValue;
 
end

endmodule
