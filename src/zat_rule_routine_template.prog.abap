*&---------------------------------------------------------------------*
*& Subroutinenpool ZAT_RULE_ROUTINE_TEMPLATE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
PROGRAM zat_rule_routine_template.
CLASS routine DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS routine_101 IMPORTING go      TYPE REF TO zat_go
                                        is_rule TYPE zat_go=>msty_rule_detail
                                        i_line  TYPE any optional
                                        i_value TYPE any optional
                              CHANGING  c_value TYPE any
                              RAISING   cx_static_check cx_dynamic_check.

    CLASS-METHODS routine_102 IMPORTING go      TYPE REF TO zat_go
                                        is_rule TYPE zat_go=>msty_rule_detail
                                        i_line  TYPE any optional
                                        i_value TYPE any optional
                              CHANGING  c_value TYPE any
                              RAISING   cx_static_check cx_dynamic_check.

    CLASS-METHODS routine_103 IMPORTING go      TYPE REF TO zat_go
                                        is_rule TYPE zat_go=>msty_rule_detail
                                        i_line  TYPE any optional
                                        i_value TYPE any optional
                              CHANGING  c_value TYPE any
                              RAISING   cx_static_check cx_dynamic_check.

    CLASS-METHODS routine_104 IMPORTING go      TYPE REF TO zat_go
                                        is_rule TYPE zat_go=>msty_rule_detail
                                        i_line  TYPE any optional
                                        i_value TYPE any optional
                              CHANGING  c_value TYPE any
                              RAISING   cx_static_check cx_dynamic_check.

    CLASS-METHODS routine_105 IMPORTING go      TYPE REF TO zat_go
                                        is_rule TYPE zat_go=>msty_rule_detail
                                        i_line  TYPE any optional
                                        i_value TYPE any optional
                              CHANGING  c_value TYPE any
                              RAISING   cx_static_check cx_dynamic_check.

    CLASS-METHODS routine_106 IMPORTING go      TYPE REF TO zat_go
                                        is_rule TYPE zat_go=>msty_rule_detail
                                        i_line  TYPE any optional
                                        i_value TYPE any optional
                              CHANGING  c_value TYPE any
                              RAISING   cx_static_check cx_dynamic_check.

    CLASS-METHODS routine_107 IMPORTING go      TYPE REF TO zat_go
                                        is_rule TYPE zat_go=>msty_rule_detail
                                        i_line  TYPE any optional
                                        i_value TYPE any optional
                              CHANGING  c_value TYPE any
                              RAISING   cx_static_check cx_dynamic_check.

    CLASS-METHODS routine_108 IMPORTING go      TYPE REF TO zat_go
                                        is_rule TYPE zat_go=>msty_rule_detail
                                        i_line  TYPE any optional
                                        i_value TYPE any optional
                              CHANGING  c_value TYPE any
                              RAISING   cx_static_check cx_dynamic_check.

    CLASS-METHODS routine_109 IMPORTING go      TYPE REF TO zat_go
                                        is_rule TYPE zat_go=>msty_rule_detail
                                        i_line  TYPE any optional
                                        i_value TYPE any optional
                              CHANGING  c_value TYPE any
                              RAISING   cx_static_check cx_dynamic_check.

    CLASS-METHODS routine_110 IMPORTING go      TYPE REF TO zat_go
                                        is_rule TYPE zat_go=>msty_rule_detail
                                        i_line  TYPE any optional
                                        i_value TYPE any optional
                              CHANGING  c_value TYPE any
                              RAISING   cx_static_check cx_dynamic_check.

    CLASS-METHODS routine_before_post IMPORTING go   TYPE REF TO zat_go
                                      CHANGING  vars TYPE zat_go=>mtty_bapi_variables
                                      RAISING   cx_static_check cx_dynamic_check.
    CLASS-METHODS routine_after_post IMPORTING go   TYPE REF TO zat_go
                                     CHANGING  vars TYPE zat_go=>mtty_bapi_variables
                                     RAISING   cx_static_check cx_dynamic_check.
ENDCLASS.

CLASS routine IMPLEMENTATION.
  METHOD routine_101.
* implementation_101
  ENDMETHOD.
  METHOD routine_102.
* implementation_102
  ENDMETHOD.
  METHOD routine_103.
* implementation_103
  ENDMETHOD.
  METHOD routine_104.
* implementation_104
  ENDMETHOD.
  METHOD routine_105.
* implementation_105
  ENDMETHOD.
  METHOD routine_106.
* implementation_106
  ENDMETHOD.
  METHOD routine_107.
* implementation_107
  ENDMETHOD.
  METHOD routine_108.
* implementation_108
  ENDMETHOD.
  METHOD routine_109.
* implementation_109
  ENDMETHOD.
  METHOD routine_110.
* implementation_110
  ENDMETHOD.
  METHOD routine_before_post.
* implementation_before_post
  ENDMETHOD.
  METHOD routine_after_post.
* implementation_after_post
  ENDMETHOD.
ENDCLASS.
