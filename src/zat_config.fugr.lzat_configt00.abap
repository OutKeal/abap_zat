*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZATT_CONTROL....................................*
DATA:  BEGIN OF STATUS_ZATT_CONTROL                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZATT_CONTROL                  .
CONTROLS: TCTRL_ZATT_CONTROL
            TYPE TABLEVIEW USING SCREEN '0002'.
*...processing: ZATT_RULE.......................................*
DATA:  BEGIN OF STATUS_ZATT_RULE                     .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZATT_RULE                     .
CONTROLS: TCTRL_ZATT_RULE
            TYPE TABLEVIEW USING SCREEN '0006'.
*...processing: ZATT_RULE_CODE..................................*
DATA:  BEGIN OF STATUS_ZATT_RULE_CODE                .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZATT_RULE_CODE                .
CONTROLS: TCTRL_ZATT_RULE_CODE
            TYPE TABLEVIEW USING SCREEN '0007'.
*...processing: ZATT_RULE_DETAIL................................*
DATA:  BEGIN OF STATUS_ZATT_RULE_DETAIL              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZATT_RULE_DETAIL              .
CONTROLS: TCTRL_ZATT_RULE_DETAIL
            TYPE TABLEVIEW USING SCREEN '0005'.
*...processing: ZATT_STEP.......................................*
DATA:  BEGIN OF STATUS_ZATT_STEP                     .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZATT_STEP                     .
CONTROLS: TCTRL_ZATT_STEP
            TYPE TABLEVIEW USING SCREEN '0003'.
*...processing: ZATT_STEP_RULE..................................*
DATA:  BEGIN OF STATUS_ZATT_STEP_RULE                .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZATT_STEP_RULE                .
CONTROLS: TCTRL_ZATT_STEP_RULE
            TYPE TABLEVIEW USING SCREEN '0004'.
*...processing: ZATT_TYPE.......................................*
DATA:  BEGIN OF STATUS_ZATT_TYPE                     .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZATT_TYPE                     .
CONTROLS: TCTRL_ZATT_TYPE
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZATT_CONTROL                  .
TABLES: *ZATT_RULE                     .
TABLES: *ZATT_RULE_CODE                .
TABLES: *ZATT_RULE_DETAIL              .
TABLES: *ZATT_STEP                     .
TABLES: *ZATT_STEP_RULE                .
TABLES: *ZATT_TYPE                     .
TABLES: ZATT_CONTROL                   .
TABLES: ZATT_RULE                      .
TABLES: ZATT_RULE_CODE                 .
TABLES: ZATT_RULE_DETAIL               .
TABLES: ZATT_STEP                      .
TABLES: ZATT_STEP_RULE                 .
TABLES: ZATT_TYPE                      .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
