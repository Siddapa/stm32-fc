#include <stdint.h>
#define RCC_BASE 0x40021000
#define RCC_APB2ENR_REGISTER (*(volatile uint32_t *)(RCC_BASE + 0x18))

// #define GPIO_CRL_REGISTER(x) (*(volatile uint32_t *)(x + 0x0))
#define GPIO_CRH_REGISTER(x) (*(volatile uint32_t *)(x + 0x4))
// #define GPIO_CRL_MODE_MASK(x) (0b11 << (x * 4))
// #define GPIO_CRL_MODE_OUTPUT(x) (0b01 << (x * 4))
// #define GPIO_CRL_CNF_MASK(x) (0b11 << ((x * 4) + 2))
// #define GPIO_CRL_CNF_OUTPUT(x) (0b00 << ((x * 4) + 2))
#define GPIO_CRH_MODE_MASK(x) (0b11 << ((x - 8) * 4))
#define GPIO_CRH_MODE_OUTPUT(x) (0b01 << ((x - 8) * 4))

#define GPIO_ODR_REGISTER(x) (*(volatile uint32_t *)(x + 0xC))
#define GPIO_ODR_PIN(x) (1 << x)

#define RCC_APB2ENR_IOPCEN (1 << 4)
#define GPIO_PORTC_BASE 0x40011000
#define GPIOC_BLINK_NUM 13

// #define RCC_APB2ENR_IOPBEN (1 << 3)
// #define GPIO_PORTB_BASE 0x40010C00
// #define GPIOB_BLINK_NUM 6

int main(void) {
    // Enable port C clock gate.
    RCC_APB2ENR_REGISTER |= RCC_APB2ENR_IOPCEN;
    GPIO_CRH_REGISTER(GPIO_PORTC_BASE) &= ~(GPIO_CRH_MODE_MASK(GPIOC_BLINK_NUM));
    GPIO_CRH_REGISTER(GPIO_PORTC_BASE) |= GPIO_CRH_MODE_OUTPUT(GPIOC_BLINK_NUM);
        
    GPIO_ODR_REGISTER(GPIO_PORTC_BASE) &= ~GPIO_ODR_PIN(GPIOC_BLINK_NUM);
	GPIO_ODR_REGISTER(GPIO_PORTC_BASE) |= GPIO_ODR_PIN(GPIOC_BLINK_NUM);

    // RCC_APB2ENR_REGISTER |= RCC_APB2ENR_IOPBEN;
	// GPIO_CRL_REGISTER(GPIO_PORTB_BASE) &= ~(GPIO_CRL_MODE_MASK(GPIOB_BLINK_NUM));
    // GPIO_CRL_REGISTER(GPIO_PORTB_BASE) |= GPIO_CRL_MODE_OUTPUT(GPIOB_BLINK_NUM);
	// GPIO_CRL_REGISTER(GPIO_PORTB_BASE) &= ~(GPIO_CRL_CNF_MASK(GPIOB_BLINK_NUM));
    // GPIO_CRL_REGISTER(GPIO_PORTB_BASE) |= GPIO_CRL_CNF_OUTPUT(GPIOB_BLINK_NUM);

	// for (;;) {
    //     // Set the output bit.
    //     GPIO_ODR_REGISTER(GPIO_PORTC_BASE) |=    GPIO_ODR_PIN(GPIOC_BLINK_NUM);
    //     // GPIO_ODR_REGISTER(GPIO_PORTB_BASE) |=    GPIO_ODR_PIN(GPIOB_BLINK_NUM);
    //     for (uint32_t i = 0; i < 400000; ++i) {
    //         __asm__ volatile("nop");
    //     }
    //     // Reset it again.
    //     GPIO_ODR_REGISTER(GPIO_PORTC_BASE) &= ~GPIO_ODR_PIN(GPIOC_BLINK_NUM);
    //     // GPIO_ODR_REGISTER(GPIO_PORTB_BASE) &= ~GPIO_ODR_PIN(GPIOB_BLINK_NUM);
    //     for (uint32_t i = 0; i < 1000000; ++i) {
    //         __asm__ volatile("nop");
    //     }
    // }
	// return 0;
}
