*****           Implementation of object type ZAT                  *****
INCLUDE <object>.
begin_data object. " Do not change.. DATA is generated
* only private members may be inserted into structure private
DATA:
  " begin of private,
  "   to declare private attributes remove comments and
  "   insert private attributes here ...
  " end of private,
  BEGIN OF key,
    atno LIKE zatt_head-atno,
  END OF key.
end_data object. " Do not change.. DATA is generated

begin_method display changing container.
SUBMIT zat_query WITH s_atno = object-key-atno.

end_method.

BEGIN_METHOD ZATCREATE CHANGING CONTAINER.
DATA:
      ISHEAD LIKE ZATS_BAPI_HEAD,
*      IVDOCNUM TYPE ZATT_HEAD-DOCNUM,
      EATNO TYPE ZATT_HEAD-ATNO,
      ESTATUS TYPE ZATT_HEAD-STATUS,
      ITITEM LIKE ZATS_BAPI_ITEM OCCURS 0,
      ETRETURN LIKE BAPIRET2 OCCURS 0.
  SWC_GET_ELEMENT CONTAINER 'IsHead' ISHEAD.
*  SWC_GET_ELEMENT CONTAINER 'IvDocnum' IVDOCNUM.
  SWC_GET_TABLE CONTAINER 'ItItem' ITITEM.
  SWC_GET_TABLE CONTAINER 'EtReturn' ETRETURN.
  CALL FUNCTION 'ZAT_CREATE'
    EXPORTING
      IS_HEAD = ISHEAD
*      IV_DOCNUM = IVDOCNUM
    IMPORTING
      E_ATNO = EATNO
      E_STATUS = ESTATUS
    TABLES
      IT_ITEM = ITITEM
      ET_RETURN = ETRETURN
    EXCEPTIONS
      OTHERS = 01.
  CASE SY-SUBRC.
    WHEN 0.            " OK
    WHEN OTHERS.       " to be implemented
  ENDCASE.
  SWC_SET_ELEMENT CONTAINER 'EAtno' EATNO.
  SWC_SET_ELEMENT CONTAINER 'EStatus' ESTATUS.
  SWC_SET_TABLE CONTAINER 'ItItem' ITITEM.
  SWC_SET_TABLE CONTAINER 'EtReturn' ETRETURN.
END_METHOD.
