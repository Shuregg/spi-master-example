`timescale 1ns / 1ps

module tb_spi_master(

    );

    logic           clk;
    logic           rst;
    logic  [2:0]    cs_i;

    logic  [12:0]   data_size_i;
    logic           MOSI_i;
    logic           sr_out_en_i;
    logic           sr_we_i;

    logic           master_mode_nrw;                //Read = 0, Write = 1;

    //  SPI Interface
    logic           MISO_i;                         //Master input Slave Output
    logic           SCLK_o;                         //Serial Clock for peripherial devices
    logic           RST_o;                          //Global reset for peripherial devices
    logic           MOSI_o;                         //Master Output Slave Input

    //  Chip Select signals
    logic           cs_flash_o;                     //Chip select for Flash memory
    logic           cs_shift_reg_o;                 //Chip select for shift register
    logic           cs_mpu_o;

    //  Shift Register Signals
    logic           sr_out_en_o;                    //Shift register output enable    
    logic           sr_we_o;
    logic           sr_wd_o;

    // Flash signals
    logic           flash_we_o;
    
    logic           is_MISO_z_i;

    spi_master2v0 dut
    (
    //  Controller Interface
    .clk_i          (clk),                        // base clock
    .rst_i          (rst),                        // Syncr global Reset
    .cs_flash_i     (cs_i[2]),                    // Slave Select (Flash)
    .cs_shift_reg_i (cs_i[1]),                    // Slave Select (pim pam pam paba bum)
    .cs_mpu_i       (cs_i[0]),                    // Slave Select (Gyroscope)
 
    .data_size_i    (data_size_i),                // Size of bit package
    .MOSI_i         (MOSI_i),                     // Bit to send
    .sr_out_en_i    (sr_out_en_i),                // Shift register output enable 
    .sr_we_i        (sr_we_i),
 
    .master_mode_nrw(master_mode_nrw),            // Read = 0, Write = 1;
 
    //  SPI Interface 
    .MISO_i         (MISO_i),                           // Master input Slave Output
    .SCLK_o         (SCLK_o),                           // Serial Clock for peripherial devices
    .RST_o          (RST_o),                           // Global reset for peripherial devices
    .MOSI_o         (MOSI_o),                           // Master Output Slave Input
 
    //  Chip Select signals
    .cs_flash_o     (cs_flash_o),                           // Chip select for Flash memory
    .cs_shift_reg_o (cs_shift_reg_o),                           // Chip select for shift register
    .cs_mpu_o       (cs_mpu_o),
 
    //  Shift Register Signals 
    .sr_out_en_o    (sr_out_en_o),                           // Shift register output enable
    .sr_we_o        (sr_we_o),
    .sr_wd_o        (sr_wd_o),

    // Flash signals
    .flash_we_o     (flash_we_o),
    .is_MISO_z_i    (is_MISO_z_i)
    );    

   // Variant #2. SPI.
   // Modules used: W25Q16 Flash memory, 7-segment indicator, 74HC595 shift register, MPU6000 sensor.
   // Tasks for testbench:
   // 1. Read 4 bytes of data from Flash memory W25Q16.
   // 2. Output the received data to eight 7-segment indicators connected via shift registers 74HC595.
   // 3. Write data to Flash memory W25Q16 at any available address.
   // 4. Read data from the W25Q16 Flash memory at any available address using the Fast Read command.
   // 5. Display the received data on 7-segment indicators.
   // 6. Read data from MPU6000 at addresses 114-117.
   // 7. Display the received data on 7-segment indicators.
   // Connect the 7-segment indicators according to the serial scheme, the other devices - according to the parallel scheme.
   
   logic [7:0]   sh_reg_trans; // reg
   logic [7:0]   sh_trans;     // wire to set trans reg
   logic         sh_trans_we;  // trans we
   
   logic [127:0] sh_reg_data;
   logic         sh_reg_data_we;
   logic         sh_reg_out_data_en;
   
   logic  [3:0]    sevenseg_decode [7:0];
   logic  [6:0]    sevenseg        [7:0];
   
   assign sh_reg_data_we     = sr_we_o;
   assign sh_reg_out_data_en = sr_out_en_o;
   
   assign MOSI_i = sh_reg_trans[7];
   
   parameter PERIOD = 7'd100;

   assign sevenseg_decode[0] = (sh_reg_out_data_en) ? sh_reg_data[3:0]   : 4'bx;
   assign sevenseg_decode[1] = (sh_reg_out_data_en) ? sh_reg_data[7:4]   : 4'bx;
   assign sevenseg_decode[2] = (sh_reg_out_data_en) ? sh_reg_data[11:8]  : 4'bx;
   assign sevenseg_decode[3] = (sh_reg_out_data_en) ? sh_reg_data[15:12] : 4'bx;
   assign sevenseg_decode[4] = (sh_reg_out_data_en) ? sh_reg_data[19:16] : 4'bx;
   assign sevenseg_decode[5] = (sh_reg_out_data_en) ? sh_reg_data[23:20] : 4'bx;
   assign sevenseg_decode[6] = (sh_reg_out_data_en) ? sh_reg_data[27:24] : 4'bx;
   assign sevenseg_decode[7] = (sh_reg_out_data_en) ? sh_reg_data[31:28] : 4'bx;

    initial begin
        // ==================== read 4 bytes from 0hBBBB_BBBB_BBBB in flash ====================
        // -------------------- send opcode and address -------------------- 
        rst             =  1'b1;
        sh_reg_trans    =  8'b0;
        sh_reg_data     =  128'b0;
        sh_reg_data_we  =  1'b0;
        sh_trans_we     =  1'b0;
        
        MISO_i          =  1'bz;
        is_MISO_z_i     =  1'b1;
        
        master_mode_nrw =  1'b0;
        
        // choose flash in selector
        #(PERIOD);
        rst         =  1'b0;
        cs_i        =  3'b100;
        data_size_i =  12'd32;

        // to send opcode
        #(PERIOD/2);
        sh_trans_we   = 1'b1;
        sh_trans = 8'h0B;
        
        // set next byte and write disable
        #(PERIOD/2);
        sh_trans_we   = 1'b0;
        
        sh_trans = 8'hBB;
        
        // wait till opcode byte is full read
        repeat (8) @(posedge clk);
        
        // to send 1st addr
        sh_trans_we   = 1'b1;
        
        
        // addr 2nd byte is the same and write enable false
        #(PERIOD/2);
        sh_trans_we   = 1'b0;
        
        repeat (8) @(posedge clk);
        
        // to send 2nd addr
        sh_trans_we   = 1'b1;
        
        // addr 3rd byte is the same and write enable false
        #(PERIOD/2);
        sh_trans_we   = 1'b0;
        
        repeat (8) @(posedge clk);
        
        // to send 3rd addr
        sh_trans_we   = 1'b1;
        
        // dummy clocks byte and write enable false
        #(PERIOD/2);
        sh_trans_we   = 1'b0;
        sh_trans = 8'hzz;
        
        repeat (8) @(posedge clk);
        
        // to send dummy byte
        sh_trans_we   = 1'b1;
        
        // write enable false, finished service frames
        #(PERIOD/2);
        sh_trans_we   = 1'b0;
        
        repeat (8) @(posedge clk);
        
        // -------------------- read data -------------------- 
        MISO_i          = 1'b1;
        is_MISO_z_i     = 1'b0;
        
        repeat (32) @(posedge clk);
        
        MISO_i          = 1'bz;
        is_MISO_z_i     = 1'b1;
        
        // ====================================== 7seg out ======================================
        cs_i        =  3'b000;
        sr_out_en_i =  1'b1;
        
        repeat (8) @(posedge clk);
        
        sr_out_en_i =  1'b0;
        
        // ==================== write 4 bytes to 0hAAAA_AAAA_AAAA in flash ====================
        // -------------------- send opcode and address --------------------  
//        rst             =  1'b1;
//        sh_reg_trans    =  8'b0;
//        sh_reg_data     =  128'b0;
//        sh_reg_data_we  =  1'b0;
//        sh_trans_we     =  1'b0;
        
//        MISO_i          =  1'bz;
//        is_MISO_z_i     =  1'b1;
        
//        master_mode_nrw =  1'b1;
        
//        // choose flash in selector
//        #(PERIOD);
//        rst         =  1'b0;
//        cs_i        =  3'b100;
//        data_size_i =  12'd16;   // 2 bytes
        
//        // to send we opcode
//        #(PERIOD/2);
//        sh_trans_we   = 1'b1;
//        sh_trans = 8'h06;
        
//        // set next opcode and write disable
//        #(PERIOD/2);
//        sh_trans_we   = 1'b0;
//        sh_trans = 8'h02;
        
//        // wait till we opcode byte is full read
//        repeat (8) @(posedge clk);
        
//        // to send we opcode
//        sh_trans_we   = 1'b1;
        
//        // set next byte and write disable
//        #(PERIOD/2);
//        sh_trans_we   = 1'b0;
//        sh_trans = 8'hAA;
        
//        // wait till opcode byte is full read
//        repeat (8) @(posedge clk);
        
//        // to send 1st addr
//        sh_trans_we   = 1'b1;
        
//        // addr 2nd byte is the same and write enable false
//        #(PERIOD/2);
//        sh_trans_we   = 1'b0;
        
//        repeat (8) @(posedge clk);
        
//        // to send 2nd addr
//        sh_trans_we   = 1'b1;        
        
//        // addr 3rd byte is the same and write enable false
//        #(PERIOD/2);
//        sh_trans_we   = 1'b0;
        
//        repeat (8) @(posedge clk);
        
//        // to send 3rd addr
//        sh_trans_we   = 1'b1;
        
//        // -------------------- send 2 bytes data --------------------  
//        // 1st byte data to send and write enable false
//        #(PERIOD/2);
//        sh_trans_we   = 1'b0;
//        sh_trans      = 8'h99;
        
//        repeat (8) @(posedge clk);
        
//        // to send 1st data byte
//        sh_trans_we   = 1'b1;
        
//        // 1st byte data to send and write enable false
//        #(PERIOD/2);
//        sh_trans_we   = 1'b0;
//        sh_trans      = 8'hAA;
        
//        repeat (8) @(posedge clk);
        
//        // to send 2nd data byte
//        sh_trans_we   = 1'b1;
        
//        // // write disable opcode set, finished service frames
//        #(PERIOD/2);
//        sh_trans_we   = 1'b0;
//        sh_trans      = 8'h04;
        
//        // write 2nd byte data
//        repeat (8) @(posedge clk);
        
        
//        // to send write disable opcode
//        sh_trans_we   = 1'b1;
        
//        #(PERIOD/2);
//        sh_trans_we   = 1'b0;
        
//        repeat (8) @(posedge clk);
        
//        // ====================================== 7seg out ======================================
//        cs_i        =  3'b000;
//        sr_out_en_i = 1'b1;
        
//        repeat (8) @(posedge clk);
        
//        sr_out_en_i = 1'b0;
        
        
        $finish();

    end



   always begin
      clk = 1'b0;
      #(PERIOD/2) clk = 1'b1;
      #(PERIOD/2);
   end
   
   always @(posedge clk) begin
      if (sh_trans_we) begin
            sh_reg_trans <= sh_trans;
      end else begin
            sh_reg_trans <= {sh_reg_trans[6:0], 1'b0};
      end
   end

    always @(posedge clk) begin
        if (sh_reg_data_we) begin
            sh_reg_data <= {sh_reg_data[126:0], sr_wd_o};
        end
    end

endmodule
