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
- IBUS Packet: ```0x2000_0000 - 0x2000_0019``` (32 bytes for all transmit data, including non-relevant channels)
- Reconstructed Packet: ```0x2000_0020 - 0x2000_002A``` (10 bytes for CHANNEL_DATA struct, could use ```packed``` to make it smaller)


## DSHOT
- DMA 1, Channel 5
- Timer 1, A8-11
- TIM1 Counter Values for Bit Encoding: ```0x2000_0030 - 0x2000_0038``` ((16 frame bits + 2 bit padding) * 4 motors )


## Gryo
- ```0x2000_0040 - 0x2000_0040``` 
