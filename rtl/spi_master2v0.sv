module spi_master2v0 (
//  Controller Interface          
    input   logic           clk_i,                          //base clock
    input   logic           rst_i,                          //Syncr global Reset
    input   logic           cs_flash_i,                     //Slave Select (Flash)
    input   logic           cs_shift_reg_i,                 //Slave Select (Flash, Giroscope)
    input   logic           cs_mpu_i,                       //Slave Select (Flash, Giroscope)

    input   logic   [12:0]  data_size_i,                    //Size of bit package
    input   logic           MOSI_i,                         //Bit to send
    // input   logic           sr_out_en_i,                    //Shift register output enable 
    // input   logic           sr_we_i,

    input   logic           master_mode_nrw,                //Read = 0, Write = 1;
//  SPI Interface
    input   logic           MISO_i,                         //Master input Slave Output
    output  logic           SCLK_o,                         //Serial Clock for peripherial devices
    output  logic           RST_o,                          //Global reset for peripherial devices
    output  logic           MOSI_o,                         //Master Output Slave Input
    //  Chip Select signals
    output  logic           cs_flash_o,                     //Chip select for Flash memory
    output  logic           cs_shift_reg_o,                 //Chip select for shift register
    output  logic           cs_mpu_o,
    //  Shift Register Signals
    output  logic           sr_out_en_o,                    //Shift register output enable    
    output  logic           sr_we_o,
    output  logic           sr_wd_o,
);
// Parameters
    parameter       MODE_R              = 1'b0;
    parameter       MODE_W              = 1'b1;
    parameter [7:0] SERVICE_BITS_VAL_R  = 8'd40;
    parameter [7:0] SERVICE_BITS_VAL_W  = 8'd40;

// Internal signals
    logic [ 7:0]    flash_data;
    logic [ 3:0]    segment_data;
    logic [ 7:0]    shift_reg_data;
    logic [15:0]    mpu_data;
    
    logic [ 7:0]    bit_counter;        //Counter for bit receive/send
    logic [ 7:0]    shift_reg;          //SPI-Master Shift reg

    logic [ 2:0]    SS_reg;

// State machine states
    typedef enum logic [2:0] {
        IDLE, FLASH_READ, FLASH_WRITE, MPU_READ, SHREG_WRITE
    } state_t;
    state_t state, next_state;

    assign  state   = next_state;    
    assign  SS_reg  = {cs_flash_i, cs_shift_reg_i, cs_mpu_i};

//========================Base clock dependencies================================================
    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            next_state      <= IDLE;
            state           <= IDLE;
            shift_reg       <= 8'h00;

            cs_flash_o      <= 1'b0;
            cs_mpu_o        <= 1'b0;
            cs_shift_reg_o  <= 1'b0;

            sr_out_en_o     <= 1'b0;
            sr_we_o         <= 1'b0;
            sr_wd_o         <= 1'b0;
        end else begin
            state           <= next_state;
        end
    end 
//========================Transaction processing (FSM)================================================
    always_ff @(posedge SCLK_o) begin
        if(rst_i) begin
            bit_counter <= 8'b0;
        end else begin
            case(state)
            //========================IDLE STATE========================      
                IDLE:           begin
                    case(SS_reg)
                    //  FLASH selected
                        3'b100: begin
                            cs_flash_o      <=  1'b1;
                            // next_state      <=  master_mode_nrw ? FLASH_WRITE : FLASH_READ;    
                            case(master_mode_nrw)
                                MODE_R: begin
                                    bit_counter <= bit_counter + 8'd40;     //8-bit instruction + 24-bit address + 8-bit dummy clocks (For Fast Read mode)
                                    next_state  <= FLASH_READ;
                                end
                                MODE_W: begin
                                    bit_counter <= bit_counter + 8'd32        //8-bit instruction + 24-bit address + Data Bytes (1 - 2079 Bytes) (For Page Program mode) 
                                    next_state  <= FLASH_WRITE;
                                end
                            endcase
                        end
                    //  SHIFT REG selected   
                        3'b010: begin
                            bit_counter     <=  8'd15;  //16 - 1
                            cs_shift_reg_o  <=  1'b1;
                            sr_we_o         <=  1'b1;
                            sr_out_en_o     <=  1'b1;
                            sr_wd_o         <=  MOSI_i;
                            next_state      <=  SHREG_WRITE;
                        end
                    //  MPU selected    
                        2'b001: begin
                            cs_mpu_o        <=  1'b1;
                            next_state      <=  MPU_READ;
                        end
                        default:
                            next_state      <=  IDLE;
                    endcase
                end
            //========================FLASH READ========================
                FLASH_READ:     begin
                    if(bit_counter != 8'b0) begin
                        bit_counter     <=  bit_counter = 8'd1;
                    end else begin
                        
                        next_state      <=  IDLE;
                    end
                    
                end
            //========================FLASH WRITE========================
                FLASH_WRITE:    begin
                    if(bit_counter != 8'b0) begin
                        bit_counter     <=  bit_counter = 8'd1;   
                    end else begin
                        next_state      <=  IDLE;
                    end
                end
                SHREG_WRITE:    begin
                    if(bit_counter != 8'b0) begin
                        bit_counter     <=  bit_counter = 8'd1;
                    end else begin
                        
                        next_state      <=  IDLE;
                    end
                end
            //========================MPU READ========================
                MPU_READ:       begin
                    if(bit_counter != 8'b0) begin
                        bit_counter     <=  bit_counter = 8'd1;
                    end else begin
                        next_state      <=  IDLE;
                    end
                end
            //========================DEFAULT STATE========================
                default:        begin
                    next_state          <=  IDLE;
                end
            endcase 
        end
    end
//========================SPI Clock logic================================================
    always_comb begin
        if(rst_i) begin
            SCLK_o  = 1'b1;
        end else begin
            case(SS_reg)
                3'b001, 3'b010, 3'b100: begin
                    SCLK_o  = clk_i;
                end
                default: begin
                    SCLK_o  = 1'b1;
                end
            endcase
        end
    end
endmodule