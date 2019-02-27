  //------------------//
  // enum: e_i2c_direction
  // Request type, read or write
  //
  // I2C_DIR_WRITE - write request
  // I2C_DIR_READ  - read request
  typedef enum {
    I2C_DIR_WRITE = 0,
    I2C_DIR_READ  = 1
  } e_i2c_direction;
    
  //------------------//
  // enum: e_i2c_frequency_mode
  // SCL frequency ranges defined in the I2C standard.
  //
  // I2C_STANDARD_MODE    - 0 : 100KHz
  // I2C_FAST_MODE        - 0 : 400KHz
  // I2C_HIGH_SPEED_MODE  - 0 : 3.4MHz
  typedef enum {
    I2C_STANDARD_MODE     = 0,
    I2C_FAST_MODE         = 1,
    I2C_HIGH_SPEED_MODE   = 2
  } e_i2c_frequency_mode;
  
  `define I2C_DEFAULT_SLAVE_ADDRESS 'h33b
