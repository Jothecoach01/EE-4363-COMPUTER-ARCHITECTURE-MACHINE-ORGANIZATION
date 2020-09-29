// Code your testbench here
// or browse Examples
//
// Test bench for the mipspipe
// Boram Lee
//
  
`include "mipspipe.v"
  
module test_mipspipe;
  
  reg clock;
  reg [3:0] clock_cycle;

// instantiate pipeline module
  mipspipe u_mipspipe(clock);
 
// initialize clock and cycle counter 
  initial begin
    clock = 0;
    clock_cycle=4'h0;
    #160  $finish;
  end
  
// 10 unit clock cycle
  always 
    #5 clock = ~clock;

  always @(posedge clock)
     begin
       clock_cycle=clock_cycle+1;
     end


// display contents of pipeline latches at the end of each clock cycle
  always @(negedge clock) 
     begin
     $display("\n\nclock cycle = %d",clock_cycle," (time = %1.0t)",$time);
     $display("\nState:");
     $display("\tIFID Stall: %s", u_mipspipe.IFIDStall?"True":"False");
       $display("\tEXMEM Stall: %s", u_mipspipe.EXMEMStall?"True":"False");
     $display("IF/ID registers\n\t IF/ID.PC+4 = %h, IF/ID.IR = %h \n", u_mipspipe.PC, u_mipspipe.IFIDIR); 
     $display("ID/EX registers\n\t ID/EX.rs = %d, ID/EX.rt = %d",u_mipspipe.IDEXrs,u_mipspipe.IDEXrt,"\n\t ID/EX.A = %h, ID/EX.B = %h",u_mipspipe.IDEXA,u_mipspipe.IDEXB);
     $display("\t ID/EX.op = %h\n",u_mipspipe.IDEXop);
     $display("EX/MEM registers\n\t EX/MEM.rs = %d, EX/MEM.rt = %d",u_mipspipe.IDEXrs,u_mipspipe.IDEXrt,"\n\t EX/MEM.ALUOut = %h, EX/MEM.ALUout = %h",u_mipspipe.EXMEMALUOut,u_mipspipe.EXMEMB);
     $display("\t EX/MEM.op = %h\n",u_mipspipe.EXMEMop);
     $display("MEM/WB registers\n\t MEM/WB.rd = %d, MEM/WB.rt = %d",u_mipspipe.MEMWBrd,u_mipspipe.MEMWBrt,"\n\t MEM/WB.value = %h",u_mipspipe.MEMWBValue);
     $display("\t EX/MEM.op = %h\n",u_mipspipe.MEMWBop);
     end
      
// log to a vcd (variable change dump) file
   initial
      begin
      $dumpfile("test_mipspipe.vcd");
      $dumpvars;
   end

endmodule
