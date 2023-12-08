`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.11.2023 21:28:33
// Design Name: 
// Module Name: SPI
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

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

// 1. Read 4 Bytes from Flash
// 2. Display this data to 8 HEXs
// 3. Write data ti Flash using any free address
// 4. Read data from flash using Fast Read and any address
// 5. Display to HEX
// 6. Read data from sensor;
// 7.Display to HEX

// MODE: CPOL = 0, CPHA = 0.

typedef enum logic [2:0] 
{
    RESET       =   3'b000
    IDLE        =   3'b001, 
    SHIFT       =   3'b010, 
    LOAD        =   3'b011,
    UNLOAD      =   3'b100
} State;


module spi_master
(
    //SPI Interface
    input   logic           MISO_i,                         //Master inpur Slave Output
    output  logic           SCLK_o,                         //Serial Clock for peripherial devices
    output  logic           RST_o                           //Global reset for peripherial devices
    output  logic           SS0_o,                            //Slave Select
    output  logic           SS1_o,                           //Slave Select
    output  logic           SS2_o,                         //Slave Select
    output  logic           MOSI_o,                         //Master Output Slave Input

    //Controller Interface          
    input   logic           clk_i,                          //base clock
    input   logic           rst_i,                          //Syncr global Reset
    input   logic           SS0_i, 
    input   logic           SS1_i, 
    input   logic           SS2_i, 
    input   logic           transaction_started_i,
    input   logic           transaction_size_i
    // input   logic   [1:0]   slave_select_i, 
    // input   
    );
    
    State state, state_next;
    
    logic [7:0] tx_data;    //transmitted data
    logic [7:0] rx_data;    //received data

    logic [9:0] bit_counter;//Counter for bit receive/send

    logic [2:0] state;      //Current state
    // logic [2:0] state_next; //Next State

    logic       SS0;        //Slave select (Flash)
    logic       SS1;        //Slave select (Shift register)
    logic       SS2;        //Slave select (Sensor (Hyroscope))


    always_ff @ (posedge clk_i) begin
        if(rst_i) begin
            state       <=  RESET;            
        end else begin
            case(state)
                RESET:
                    state   <=   IDLE;
                IDLE:
                    case(transaction_started_i)
                        1'b0:   state   <=   IDLE;
                        1'b1:   state   <=   SHIFT;
                    endcase
                SHIFT:

                LOAD:

                UNLOAD:

            endcase
            
        end
    end    

    always_comb begin// : FSM
        case(state)
            RESET:  begin
                MISO_i      <=  1'b0;
                MOSI_o      <=  1'b1;
                tx_data     <=  8'b0;
                rx_data     <=  8'b0;
                bit_counter <=  10'b0;
            end
            IDLE:   begin
                case(SS)
                    2'b00:
                        state_next  <= IDLE;
                    2'b00: begin       //FLASH

                    end

                    2'b00: begin

                    end

                    2'b00: begin

                    end

                    default: begin
                        state_next  <= IDLE;
                    end

                endcase
            end

        endcase
    end
endmodule
 
