const std = @import("std");
const dshot = @import("protocols/dshot.zig");

pub fn exportVectorTable() void {
    @export(&vector_table, .{
        .name = "vector_table",
        .section = ".isr_vector",
        .linkage = .strong,
    });
}

fn defaultHandler() callconv(.c) noreturn {
    while (true) {}
}

const resetHandler = @import("startup.zig").resetHandler;

/// The __stack symbol we defined in our linker script for where the stack pointer should
/// start (the very end of RAM). Note is given the type "anyopaque" as this symbol is
/// only ever meant to be used by taking the address with &. It doesn't actually "point"
/// to anything valid at all!
extern var __stack: anyopaque;

/// The actual instance of our vector table we will export into the section
/// ".isr_vector", ensuring it is placed at the beginning of flash memory.
/// Actual interrupt handlers (rather than the defaultHandler) could be added
/// by assigning them in struct instantiation.
const vector_table: VectorTable = .{
    .initial_stack_pointer = &__stack,
};

/// Note that any interrupt function is specified to use the "c" calling convention.
/// This is because Zig's calling convention could differ from C. C being the defacto
/// "standard" for function calling conventions, it's what the processor expects when
/// it branches to one of these functions. Normal functions in application code, however
/// can use normal Zig function definitions. These functions are "special" in the sense
/// that they are being called by "hardware" directly.
const IsrFunction = *const fn () callconv(.c) void;

/// An "extern" struct here is used here to create a
/// struct that has the same memory layout as a C struct.
/// Note that this is NOT the same as "packed", so care must be taken
/// to match the memory layout the CPU is expecting. In this case
/// all fields are ultimately a u32, so silently added padding bytes
/// aren't a concern.
const VectorTable = extern struct {
    initial_stack_pointer: *anyopaque,
    Reset_Handler: IsrFunction = resetHandler,
    NMI_Handler: IsrFunction = defaultHandler,
    HardFault_Handler: IsrFunction = defaultHandler,
    MemManage_Handler: IsrFunction = defaultHandler,
    BusFault_Handler: IsrFunction = defaultHandler,
    UsageFault_Handler: IsrFunction = defaultHandler,
    reserved1: [4]u32 = undefined,
    SVC_Handler: IsrFunction = defaultHandler,
    DebugMon_Handler: IsrFunction = defaultHandler,
    reserved2: u32 = undefined,
    PendSV_Handler: IsrFunction = defaultHandler,
    SysTick_Handler: IsrFunction = defaultHandler,
    WWDG_IRQHandler: IsrFunction = defaultHandler,
    PVD_IRQHandler: IsrFunction = defaultHandler,
    TAMP_STAMP_IRQHandler: IsrFunction = defaultHandler,
    RTC_WKUP_IRQHandler: IsrFunction = defaultHandler,
    FLASH_IRQHandler: IsrFunction = defaultHandler,
    RCC_IRQHandler: IsrFunction = defaultHandler,
    EXTI0_IRQHandler: IsrFunction = defaultHandler,
    EXTI1_IRQHandler: IsrFunction = defaultHandler,
    EXTI2_IRQHandler: IsrFunction = defaultHandler,
    EXTI3_IRQHandler: IsrFunction = defaultHandler,
    EXTI4_IRQHandler: IsrFunction = defaultHandler,
    DMA1_Channel1_IRQHandler: IsrFunction = defaultHandler,
    DMA1_Channel2_IRQHandler: IsrFunction = defaultHandler,
    DMA1_Channel3_IRQHandler: IsrFunction = defaultHandler,
    DMA1_Channel4_IRQHandler: IsrFunction = defaultHandler,
    DMA1_Channel5_IRQHandler: IsrFunction = dshot.complete_transfer,
    DMA1_Channel6_IRQHandler: IsrFunction = defaultHandler,
    DMA1_Channel7_IRQHandler: IsrFunction = defaultHandler,
    ADC_IRQHandler: IsrFunction = defaultHandler,
    USB_HP_CAN_TX: IsrFunction = defaultHandler,
    USB_LP_CAN_RX: IsrFunction = defaultHandler,
    CAN1_RX0_IRQHandler: IsrFunction = defaultHandler,
    CAN1_SCE_IRQHandler: IsrFunction = defaultHandler,
    EXTI9_5_IRQHandler: IsrFunction = defaultHandler,
    TIM1_BRK_TIM9_IRQHandler: IsrFunction = defaultHandler,
    TIM1_UP_TIM10_IRQHandler: IsrFunction = defaultHandler,
    TIM1_TRG_COM_TIM11_IRQHandler: IsrFunction = defaultHandler,
    TIM1_CC_IRQHandler: IsrFunction = defaultHandler,
    TIM2_IRQHandler: IsrFunction = defaultHandler,
    TIM3_IRQHandler: IsrFunction = defaultHandler,
    TIM4_IRQHandler: IsrFunction = defaultHandler,
    I2C1_EV_IRQHandler: IsrFunction = defaultHandler,
    I2C1_ER_IRQHandler: IsrFunction = defaultHandler,
    I2C2_EV_IRQHandler: IsrFunction = defaultHandler,
    I2C2_ER_IRQHandler: IsrFunction = defaultHandler,
    SPI1_IRQHandler: IsrFunction = defaultHandler,
    SPI2_IRQHandler: IsrFunction = defaultHandler,
    USART1_IRQHandler: IsrFunction = defaultHandler,
    USART2_IRQHandler: IsrFunction = defaultHandler,
    USART3_IRQHandler: IsrFunction = defaultHandler,
    EXTI15_10_IRQHandler: IsrFunction = defaultHandler,
    RTC_Alarm_IRQHandler: IsrFunction = defaultHandler,
    USB_WKUP_IRQHandler: IsrFunction = defaultHandler,
    TIM8_BRK_TIM12_IRQHandler: IsrFunction = defaultHandler,
    TIM8_UP_TIM13_IRQHandler: IsrFunction = defaultHandler,
    TIM8_TRG_COM_TIM14_IRQHandler: IsrFunction = defaultHandler,
    TIM8_CC_IRQHandler: IsrFunction = defaultHandler,
    ADC3_IRQHandler: IsrFunction = defaultHandler,
    FSMC_IRQHandler: IsrFunction = defaultHandler,
    TIM5_IRQHandler: IsrFunction = defaultHandler,
    SPI3_IRQHandler: IsrFunction = defaultHandler,
    UART4_IRQHandler: IsrFunction = defaultHandler,
    UART5_IRQHandler: IsrFunction = defaultHandler,
    TIM6_DAC_IRQHandler: IsrFunction = defaultHandler,
    TIM7_IRQHandler: IsrFunction = defaultHandler,
    DMA2_Channel1_IRQHandler: IsrFunction = defaultHandler,
    DMA2_Channel2_IRQHandler: IsrFunction = defaultHandler,
    DMA2_Channel3_IRQHandler: IsrFunction = defaultHandler,
    DMA2_Channel4_5_IRQHandler: IsrFunction = defaultHandler,
};
