## Clocks
- Peripheral Clock: HSE -> 8MHz
- PLL Input: HSE / 2 -> 4MHz
- PLL Scaler: PLL Input * 6 -> 24MHz
- APB2: Same as PLL Scaler -> 24 MHz
- APB1: Same as PLL Scaler -> 24 MHz

## Debug
- USART 1 TX: B6 (alternate port since blocked by DSHOT)
    - BRR Value: APB2 @ 115,200 bps -> 208
- No DMA, fill DR reg manually with data (blocking function call to write to terminal)


## IBUS
- USART 2 RX: A3
    - BRR Value: APB1 @ 115,200 bps -> 208
- DMA 1, Channel 6 
- Memory Zones:
    - Frame - `0x2000_0000 - 0x2000_0020`
        - 32 bytes for all transmit data, including non-relevant channels
    - Transmit Data - `0x2000_0020 - 0x2000_002C`
        - Padded 12 bytes for CHANNEL_DATA struct, could use `packed` to make it smaller


## DSHOT
- Timer 1, A8-11
- DMA 1, Channel 5
- Memory Zone:
    - TIM1 Counter Values for Bit Encoding: `0x2000_0030 - 0x2000_0039` ((16 frame bits + 2 bit padding) * 4 motors )


## Gryo
- SPI 1: A5-A7 (CLK, MISO, MOSI)
- DMA Mappings:
    - DMA 1, Channel 2 for RX
    - DMA 1, Channel 3 for TX
- Memory Zones:
    - TX Buffer - `0x2000_0040 - 0x2000_004F`
        - 1 byte for imu address + 14 bytes of empty data
    - RX Buffer - `0x2000_0050 - 0x2000_005E`
        - 14 bytes of imu data (6 accel axis, 6 gryo axis, and 2 temps)
    - RX Data - `0x2000_0060 - 0x2000_006E`
