// #include <stdint.h>
// 
// 
// #define PERIPHERAL_BASE                          (0x40000000)
// #define RCC_BASE               (PERIPHERAL_BASE + 0x00021000)
// #define GPIOC_BASE             (PERIPHERAL_BASE + 0x00011000)
// 
// #define RCC_APB2_OFFSET        (0x18)
// #define RCC_APB2               ((volatile uint32_t*) RCC_BASE + RCC_APB2_OFFSET)
// 
// #define GPIOC_CRL_OFFSET       (0x04) // Controls CNF/MODE
// #define GPIOC_CRL              ((volatile uint32_t*) GPIOC_BASE + GPIOC_CRL_OFFSET)
// 
// #define GPIOC_ODR_OFFSET   	   (0x0C)
// #define GPIOC_ODR          	   ((volatile uint32_t*) GPIOC_BASE + GPIOC_ODR_OFFSET)
// 
// #define RCC_APB2_GPIOC_ENABLE  (0b10000)
// #define GPIOC_CRL_LED   (0x00100000) // Enables pin 13 to be output
// #define LED_PIN 13
// 
// int main(void) {
// 	*RCC_APB2 |= RCC_APB2_GPIOC_ENABLE;
// 	*GPIOC_CRL |= GPIOC_CRL_LED;
// 
// 	while(1) {
// 		*GPIOC_ODR ^= (1 << LED_PIN);
// 		for (int i = 0; i < 100000; i++) {}
// 	}
// }


#include <stdint.h>
#define RCC_BASE 0x40021000
#define RCC_APB2ENR_REGISTER (*(volatile uint32_t *)(RCC_BASE + 0x18))
#define RCC_APB2ENR_IOPCEN (1 << 4)
#define GPIO_PORTC_BASE 0x40011000
#define GPIO_CRH_REGISTER(x) (*(volatile uint32_t *)(x + 0x4))
#define GPIO_CHR_MODE_MASK(x) (0x3 << ((x - 8) * 4))
#define GPIO_CHR_MODE_OUTPUT(x) (0x1 << ((x - 8) * 4))
#define GPIO_ODR_REGISTER(x) (*(volatile uint32_t *)(x + 0xC))
#define GPIO_ODR_PIN(x) (1 << x)
#define GPIO_BLINK_PORT GPIO_PORTC_BASE
#define GPIO_BLINK_NUM 13

int main(void) {
    // Enable port C clock gate.
    RCC_APB2ENR_REGISTER |= RCC_APB2ENR_IOPCEN;    // Configure GPIO C pin 13 as output.
    GPIO_CRH_REGISTER(GPIO_BLINK_PORT) &= ~(GPIO_CHR_MODE_MASK(GPIO_BLINK_NUM));
    GPIO_CRH_REGISTER(GPIO_BLINK_PORT) |= GPIO_CHR_MODE_OUTPUT(GPIO_BLINK_NUM);    for (;;) {
        // Set the output bit.
        GPIO_ODR_REGISTER(GPIO_BLINK_PORT) |=    GPIO_ODR_PIN(GPIO_BLINK_NUM);
        for (uint32_t i = 0; i < 400000; ++i) {
            __asm__ volatile("nop");
        }
        // Reset it again.
        GPIO_ODR_REGISTER(GPIO_BLINK_PORT) &= ~GPIO_ODR_PIN(GPIO_BLINK_NUM);
        for (uint32_t i = 0; i < 100000; ++i) {
            __asm__ volatile("nop");
        }
    }    return 0;
}
