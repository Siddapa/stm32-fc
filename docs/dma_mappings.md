## IBUS
- IBUS Packet: ```0x2000_0000 - 0x2000_0019``` (32 bytes for all transmit data, including non-relevant channels)
- Reconstructed Packet: ```0x2000_0020 - 0x2000_002A``` (10 bytes for CHANNEL_DATA struct, could use ```packed``` to make it smaller)


## DSHOT
- TIM1 Counter Values for Bit Encoding: ```0x2000_0030 - 0x2000_0038``` ((16 frame bits + 2 bit padding) * 4 motors )


## GYRO
- ```0x2000_0040 - 0x2000_0040``` 
