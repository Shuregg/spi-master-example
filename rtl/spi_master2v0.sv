module spi_master2v0 (


//  Controller Interface          
    input   logic           clk_i,                          //base clock
    input   logic           rst_i,                          //Syncr global Reset
    input   logic           cs_flash_i,                     //Slave Select (Flash)
    input   logic           cs_shift_reg_i,                 //Slave Select (Flash, Giroscope)
    input   logic           cs_mpu_i,                       //Slave Select (Flash, Giroscope)

    input   logic   [7:0]   data_size_i,                    //Size of bit package
    input   logic           MOSI_i,                         //Bit to send
    input   logic           sr_out_en_i,                    //Shift register output enable 
    input   logic           sr_we_i,

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
// Internal signals
    logic [ 7:0]    flash_data;
    logic [ 3:0]    segment_data;
    logic [ 7:0]    shift_reg_data;
    logic [15:0]    mpu_data;
    
    logic [ 7:0]    bit_counter;        //Counter for bit receive/send
    logic [ 7:0]    shift_reg;          //SPI-Master Shift reg

    logic [ 3:0]    SS_reg;

// State machine states
    typedef enum logic [2:0] {
        IDLE, FLASH_READ, FLASH_WRITE, MPU_READ
    } state_t;
    state_t state, next_state;

    assign  state   = next_state;    
    assign  SS_reg  = {cs_flash_i, cs_shift_reg_i, cs_mpu_i};

// FSM
    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            next_state      <= IDLE;
            shift_reg       <= 8'h00;
            cs_flash_o      <= 1'b0;
            cs_mpu_o        <= 1'b0;
            cs_shift_reg_o  <= 1'b0;
        end else begin
            state           <= next_state;
            case(state)
                IDLE:           begin
                    case(SS_reg)
                    //  FLASH selected
                        3'b100: begin
                            cs_flash_o      <=  1'b1;
                            next_state      <=  master_mode_nrw ? FLASH_WRITE : FLASH_READ;    
                        end
                    //  SHIFT REG selected   
                        3'b010: begin
                            cs_shift_reg_o  <=  1'b1;
                            next_state      <=  
                        end
                    //  MPU selected    
                        3'b001: begin

                            next_state      <=
                        end
                        default:
                            next_state      <=  IDLE;
                    endcase
                end

                FLASH_READ:     begin
                    next_state  <=  
                end

                FLASH_WRITE:    begin
                    next_state  <=
                end

                MPU_READ:       begin
                    next_state  <=
                end

                default:        begin
                    next_state  <=  IDLE;
                end
            endcase 
        end
    end 
endmodule