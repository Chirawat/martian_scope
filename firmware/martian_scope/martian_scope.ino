#define COMP_PROBE            0
#define SAMPLING_RATE_PROBE   1 
#define ADC_PROBE             2
#define SAMPLING_PERIOD_PROBE 3
#define RX_PROBE              4
#define LED                   5
#define TX_BUFFER_SIZE 1024
#define RX_BUFFER_SIZE 16
#define DATA_BUFFER_SIZE 64

// State
#define CHECK 0x01
#define OPERATE 0x02

// Command
#define CMD_WRITE   0x10
#define CMD_READ    0x11

// Response
#define ACK             0x01

#define NAK             0x80
#define NO_DATA         0x01
#define PREAMBLE_ERROR  0x02
#define CHECKSUM_ERROR  0x04


uint8_t state;
uint8_t result;
volatile uint16_t   tx_head;
volatile uint16_t   tx_tail;
volatile uint16_t   tx_count;
volatile uint8_t    tx_buffer[TX_BUFFER_SIZE];

volatile uint8_t    rx_head;
volatile uint8_t    rx_tail;
volatile uint8_t    rx_count;
volatile uint8_t    rx_buffer[RX_BUFFER_SIZE];

volatile uint8_t    sampleCount = 1;
volatile uint16_t   tmr2Tick;

uint8_t cmd, len;
uint8_t *data;
uint8_t dataBuffer[DATA_BUFFER_SIZE];

ISR(ANALOG_COMP_vect){
  PORTB   |=  (1<<COMP_PROBE);
  PORTB   &=  ~(1<<COMP_PROBE);
  ACSR    &=  ~(1<<ACIE);                   // Disable Comparator Interrupt
  TCNT1   =   0xFF5F;    
  TIFR1   =   0x01;                         // Clear timer 1 interrupt flag
  TIMSK1  |=  (1<<0);                       // Enable timer 1 interrupt
  ADCSRA  |=  (1<<ADEN) | (1<<ADIE);        // Enable ADC, enable interrupt
}

ISR(TIMER1_OVF_vect){
  PORTB   ^=  (1<<SAMPLING_RATE_PROBE);
  PORTB   ^=  (1<<SAMPLING_RATE_PROBE);
  TCNT1   =   0xFF5F;                           
}

ISR(ADC_vect){ 
  PORTB   ^=  (1<<ADC_PROBE);
  PORTB   ^=  (1<<ADC_PROBE);
  PORTB   |= (1<<SAMPLING_PERIOD_PROBE);
  writeTxBuffer(ADCH);
  TCCR2B  =   0x07;                         // Set timer 2 prescale /1024
  TIMSK2  |=  (1<<0);                       // Enable timer 2 interrupt
}

ISR(TIMER2_OVF_vect){
  tmr2Tick++;
  TCNT2 = 0x62;
  if(tmr2Tick == 5){
    PORTB ^= (1<<SAMPLING_PERIOD_PROBE);
    TCCR1B  = 0x00;                         // Disable timer 1 clock
    TCCR2B  = 0x00;                         // Disable timer 2 clock
    TIMSK1  &=  ~0x01;                      // Disable timer 1 interrupt
    TIMSK2  &=  ~0x01;                      // Disable timer 2 interrupt
    ADCSRA  &= ~(1<<ADIE);                  // Disablel ADC interrupt
    tmr2Tick = 0;
    
    UDR0 = 0xAA; // Preamble
    while ( !( UCSR0A & (1<<UDRE0)) );
    UDR0 = tx_count; // Length byte high
    while ( !( UCSR0A & (1<<UDRE0)) );
    UDR0 = tx_count >> 8; // Length byte low
  }
}

ISR(USART_TX_vect){
  if(tx_count > 0){
    while ( !( UCSR0A & (1<<UDRE0)) );
    UDR0 = readTxBuffer();
  }
}

ISR(USART_RX_vect){
  PORTB ^= (1<<RX_PROBE);
  writeRxBuffer(UDR0);
}

void writeTxBuffer(uint8_t data){
  if(tx_count < TX_BUFFER_SIZE){
    tx_buffer[tx_head] = data;
    tx_head = (tx_head + 1) % TX_BUFFER_SIZE;
    tx_count++;
  }
}

uint8_t readTxBuffer(){
  uint8_t val;
  if(tx_count > 0){
    val = tx_buffer[tx_tail];
    tx_tail = (tx_tail + 1) % TX_BUFFER_SIZE;
    tx_count--;
  }
  return val;
}

void flushTxBuffer(){
  tx_head       = 0;
  tx_tail       = 0;
  tx_count      = 0;
}

void writeRxBuffer(uint8_t data){
  rx_buffer[rx_head] = data;
  rx_head = (rx_head + 1) % RX_BUFFER_SIZE;
  rx_count++;
}

uint8_t readRxBuffer(){
  uint8_t val = rx_buffer[rx_tail];
  rx_tail = (rx_tail + 1) % RX_BUFFER_SIZE;
  rx_count--;
  return val;
}

void setup() {
  // Disable global interrupt
  cli();
  
  // Probe
  DDRB      = 0xFF;
   
  // UART
  UBRR0     = 8;
  UCSR0A    = (1<<RXC0) | (1<<TXC0);
  UCSR0B    = (1<<RXEN0) | (1<<TXEN0) | (1<<TXCIE0) | (1<<RXCIE0);
  UCSR0C    = (3<<UCSZ00);

  // Buffer
  tx_head       = 0;
  tx_tail       = 0;
  tx_count      = 0;

  // Analog Comparator
  DIDR0 = 0xFF;             // Disable digital buffer on analog ports
  ADMUX = 0x00;             // Set ADC Mux to ADC0
  ADCSRA &= ~(1<<ADEN);     // Disable ADC
  ADCSRB |= (1<<ACME);      // Enable ADC Mux
  ACSR = (0<<ACD) | (0<<ACBG) | (1<<ACIE) | (0<<ACIC) | (1<<ACIS1) | (0<<ACIS0);
  
  // Timer 1 - Sampling Rate
  TCCR1A  = 0x00;
  TCCR1B  = 0x01;
  TCNT1   = 0xFF5F; 

  // Timer 2 - Sampling Period
  TCCR2A  = 0x00;
  TCCR2B  = 0x00;   // timer stop
  TIFR2   = 0x01;  
  TCNT2   = 0x62;

  //ADC
  ADCSRA  &= ~0x07;              // ADC Prescaller /8
  ADCSRA  |= 0x02;
  ADCSRA  |=  (1<<ADATE);         // Enable auto trigger
  ADCSRB  |= (1<<ADTS2) | (1<<ADTS1) | (0<<ADTS0);
  ADMUX   |= (1<<REFS0) | (1<<ADLAR);                                    // Select AVcc as reference, left align data

  // Enable global interrupt
  sei();
}

void startSendPacket(){
  if(tx_count > 0){
    UDR0 = readTxBuffer();
  }
}

void sendPacket(uint8_t result, uint8_t len, uint8_t *data){
  // write data into FIFO
  writeTxBuffer(0xAA); // preamble
  writeTxBuffer(10); // len
  for(uint8_t i = 0; i < 10; i++){
    writeTxBuffer(i);
  }
  // send first byte, next byte will be sent by ISR
  startSendPacket();
}

uint8_t isValidPacket(){
  if(rx_count > 0){
    if(readRxBuffer() != 0xAA){
      return NAK | PREAMBLE_ERROR;
    }
    return ACK;
  }
  return NAK;
}

void loop() {
    switch(state){
      case CHECK:
        result = isValidPacket();
        if(result == ACK){
          cmd = readRxBuffer();
//          len = readRxBuffer();
          state = OPERATE;
        }
        break;
      ////////////////////////////////////////////////////////////////////////  
      case OPERATE: 
        switch(cmd){
          case CMD_WRITE:
            PORTB &= ~(1<<LED);
            PORTB |= (readRxBuffer()<<LED);
            for(uint8_t i = 0; i < 10; i++){
              dataBuffer[i] = i+1;
            }
            sendPacket(ACK, 10, &dataBuffer[0]);
            break;
          case CMD_READ:
            break;
        }
        state = CHECK;
        break;
      //////////////////////////////////////////////////  
      default:
        state = CHECK;
        break;
  }
}
