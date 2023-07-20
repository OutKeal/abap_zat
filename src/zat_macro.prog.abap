*&---------------------------------------------------------------------*
*& 包含               ZAT_MACRO
*&---------------------------------------------------------------------*
DEFINE return_error.
  IF sy-subrc NE 0.
    me->ret-msgty = 'E'.
    me->ret-msgno = &1.
    APPEND VALUE #(  TYPE = me->ret-msgty
                                   ID = 'ZAT'
                                   NUMBER = &1
                                ) TO ret-return.
    break( ).
    RETURN.
  ENDIF.
END-OF-DEFINITION.
