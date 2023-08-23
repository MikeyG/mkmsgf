;       SCCSID = @(#)msgfin.asm 6.17 92/03/26

        PAGE    ,132
;********************************************************************
; MSGFIN.ASM:  Retrieve system messages & some other odds-n-ends
;***********************************************
;   Modification history
;
; new stuff for driver 2A:
;
;4-13   Get BOOT disk device to find message file (GetBootRoot)
;4-6    Fold filename to uppercase for Ram message support (Fold_up)
;4-10   Return linked in messages with error code (Error_Ret) (see msgfins.asm)
;4-8    Ram messages support (RamFind)
;4-11   Ram messages support - change name to DosTrueGetMessage
;4-3    DBCS consideration when searching for %n in message (Copy_Message)
;4-6    New message file header (Val_Format)
;4-6    Word vs. DWord msg offsets in message file (Val_Mid_Num,Get_Message)
;4-6    Skip Error class byte (1 byte) when copy message (Copy_Message)
;4-9    Strip filename out of input filename (Filename_Strip)
;4-11   Rename DosGetMessage to DosTrueGetMessage (for Ram Messages support)
;4-23   include error2.inc added
;4-25   fix copyretmsg to load err_ivtable with pointer to filename
;5-6    fix getbootroot to correctly point to ':'
;5-7    fix main to check for MSGSEGMENT = 0 before calling RAMFIND
;5-7    fix main to skip freeing msg_sel when RAM msg is found
;5-9    fix main to check for EOF character in message
;5-13   fix pointer to filename when 1srt open failed and drive letter was specified
;5-13   add drive_spec flag to indicate if input filename has drive specified
;5-20   fix fold_up, filename_strip routines to check for length of filename,
;       when in DBCS mode, before bumping pointers.
;5-21   fix fold_up routine to call doscasemap only if char > 127 ASCII exists in filename
;6-5    DCR 244: add decdump routine to convert binary message number to ascii
;6-5    get error message text from msg.txt which is built using MKMSGF /asm
;6-5    fix pointer to filename when 1srt open failed and drive letter was specified
;6-5    add drive_spec flag to indicate if input filename has drive specified
;6-5    add ivcount <=9 check at top of logic
;6-5    add DCR 244: add copymsghdr coutine to copy message header to callers buffer
;6-5    include BASEMID.INC for getting error msg numbers
;6-5    skip close file handle if RAM message found
;6-6    implement DCR 320 - change order of DosInsMessage parms
;6-6    make fixes to support FamilyAPI (3X BOX)
;6-10   delete second ram msg check (1 is enough)
;6-10   fix file setup when return error so that, if storage for filename
;       was not allocated, get input filename pointer.
;6-11   make fixes to replace DOSGETDBCSEV far call with CHECK_DBCS near call
;       to increase performance (ptm 580)
;6-18   REM out component ID and msg number for msg header code (move to 1.1)
;       in other words DISABLE DCR 244 ! (ptm 816)
;7-11   fix ptm 1242: change ISEG class type from 'local' to 'data' for
;       FamilyApi only
;7-14   implement DCR 373: get boot drive letter from Infoseg when in Protect
;       mode (use COMSPEC when in 3xBox)
;7-15   Fix Filename_strip routine to calculate filename length correctly when
;       backslash or colon found so it is saved correctly!
;7-24   Implement 2nd half of DCR 244 - if path not specified, get message file
;       from root directory on boot drive, if not found, look for file in
;       current directory of default drive ! (for Louise)
;7-28   Ignore bad return from DOSCASEMAP call
;7-29   fix Family API version, so that 102 bytes of local variables are generated
;8-4    fix Family API version, so that MSGSEG gets loaded into DATA segment properly
;8-19   modify getting/saving of component ID: get it from message file header, and
;       save it in SAVE structure
;8-20   RE-enable dcr 244 display msg ID's only when Error or Warning message returned
;8-28   fix Family API version, to find message file in ROOT of default drive
;8-29   fix performance/hang problem: in filename_strip, must reset filename pointer
;8-29   fix stack frame allocation for real mode only - alloc 98 bytes of user stack
;9-2    modify RAMFIND calling procedure to add pointer to component id field
;9-3    fix Family API version, to use RealEnter macro to setup stack frame
;9-15   fix main routine to return most recent error to caller
;9-15   fix copyretmsg routine to return filename ONLY when can't find message file (ptm p3599)
;10-27  fix val_format routine to remedy bug introduced when added code
;       to save component id.
;12-6   Add DCR569 support: DPATH and DosSearchPath are used intead of Append
;       in protect mode.
;12-9   Add Trace Hooks support in protect mode.
;12-11  changed cmp reg,0 -> or reg,reg to shrink code. (a tiny bit!!)
;12-12  changed getting the resident messages code (uses msg.inc)
;1-26-87 fix storing filename in Uppercase !!
;1-30-87 fix protect mode file not found logic when get other than
;        file not found error on fully qualified path file open
;4-20-87 Use new and improved messages. Use new message include file
;        msgfin.inc.
;        Also, return mid not found if msg class = ? (unknown)
;5-19-87 Add new error check (error_filename_exced_range) for filename
;        > 8.3 on return from do_open.
;6-03-87 Since there is no real way to get the BOOT DRIVE in 3xBOX (for
;        now), skip call to getbootroot in FAPI code !!
;6-11-87 But we'll fake getting the boot drive in the 3xBox by going
;        to 'C:' to get the message file!!
;        align all data segments on para boundary
;6-26-87 For REAL mode: use public symbols in MSGSEG message segment
;        in API.LIB (msg.obj) to get error messages.
;7-15-87 Add filename buffer in ISEG to allow filename
;        case mapping and path manipulation -> to avoid Alloc/Free calls.
;8-08-87 Add test_open_err routine to check for error_open_failed or
;        error_path_not_found errors from the do_open call.
;        Also, restored the old real mode GetBootRoot (scans environment
;        for COMSPEC= string.) to return better 'boot' drive letter.
;9-30-87 Added check for bad path to FIND_FILE.  It will return File
;        Not Found error instead of MSG318, regardless of the setting
;        of DPATH (PTM 750). WWM
;12-06-87 Moved get/clear semaphore to serialize dosgetmessage on a thread
;         basis.  @WWM
;3-29-88 Changes for MASM 5.0 compiler, changed class name of iseg to locald
;        and changed local variable in MSGTRACE from length to lngth.
;5-12-88 Changed test_open_error to check for ERROR_FILE_NOT_FOUND
;9-27-88 @@1 Modified MsgTrace to support performance tracing. WWM
;2-13-89 Changed Find_File to work on filenames > 8.3 characters, and also
;        modified the search algorithm.  We now always check the root of the
;        boot drive if the file can't be found anywhere else.  WWM
;3-03-89 Modified Find_File to translate ERROR_INVALID_NAME to RC = 2.
;5-16-89 Added error_invalid_name and error_envvar_not_found to
;        test_open_error.  WWM
;5-23-89 Removed MsgTrace routine and Pre and Post tracing code. WWM
;10-18-89 Changed the semaphore to a FSRamSem. An exit list routine is not
; ##1     needed because the thread is in an instance data seg.  PTR B707865
;10-18-89 Changed Test_Open_Err to use a look up table, and added the network
;         errors.  PTR B708096
;;;;;DCR361
;12-12-89 DCR361 code added caused the whole MSGFIN.ASM looked like
;         "SPAGHETTI". Especially added that whenever there is an error
;         in any extend sub record, it went to root message file.
;         I don't like it but compatible to "OLD" version, it is required.
;01-11-90 PTR B787576  Changed XFER_FILENAME and FIND_FILE to use the correct
;         segment (DS) for references to temp.
;04-03-90 @1 SDD declared a bunch of labels as public to aid debugging.  When
;         I started this file had about 4 publics to work with.
;04-04-90 @2 SDD PTR CP20-B712307  If the root file doesn't match the calling
;         processes codepage and there are no extended headers that match
;         then when you use the root file for the message save the handle.
;04-04-90 @3 SDD Also added a comment or two.
;04-05-90 @4 SDD some data was moved off the stack into ISEG.  Caused a bug
;         in finding a subfile.
;04-24-90 PTR B712660  Added assume statement to XFER_FILENAME.  WWM
;05-16-90 PTR B713044  Added for performance hook.  BHC
;05-18-90 BHC.  DCR900 to handle bound error messages.
;06-05-90 PTR B713546  Fixed bug in extended header logic.  WWM  ##3
;07-27-90 BHC. PTR B714798  Fixed error message header info.
;08-13-90 BHC. PTR B715212  Fixed last message number.
;
;B001 PB717389 04/01/91 Add TRACE support for DosQueryMessage
;B002 PB715542 04/01/91 Message prefix for SYS319 not correct
;B006 PB723098 05/20/91 fgw TrapD when IVCOUNT exceeds max allowed of 9
;B011 PAA03785 07/12/91 fgw Remove extraneous MMIOPH data (DosQueryMessage)
;B028 PB725896 11/08/91 fgw FVT manual test case error: wrong return code
;                                                     : incorrect message id's
;B029 PB726919 11/10/91 fgw MSR: MSGBIND protect mode runtime problem
;                                (code page access from wrong seg reg)
;B032 PB729690 11/21/91 fgw MSR: Garbage messages when OS/2 session opened
;B036 PJ200382 02/08/92 fgw Windowed OS/2 command prompt loops in CodePage 932
;B037 PJ200380 02/15/92 fgw Unable to access sub-message file messages.
;B038 PB734264 03/05/92 fgw Code page 932 (Hebrew) access fails during DIR.
;B038 PJ200380 03/10/92 fgw This also cleans up the J200380 problems
;                           which occur because DOSGETCP functions strangely.
;B039 PB732264 03/26/92 fgw Bound message support incompatable with 1.3
;@F03 D-053583 11/24/92 fgw Message files left open after boot-up;
;                           add DOSCLOSEMESSAGEFILE to close them on request.
;@F04 D-052172 12/10/92 fgw Message prefix changed to SYS, but no errors.
;B040 91948    08/01/94 jmh Change msg 318 to display msgnum like msg 317.
;@117349       03/29/95 bz  Moved the acquiring of the semaphore to the
;                           beginning of FIND_FILE.
;*********************************************************************
.XALL
.LIST
IFNDEF  FamilyAPI
.286c
ENDIF   ;FamilyAPI

        TITLE   Message Retriever - DosTrueGetMessage - IBM CONFIDENTIAL
        SUBTTL  Externals
        PAGE    ,132
;/********************** START OF SPECIFICATIONS **********************/
;/* SOURCE FILE NAME:  MSGFIN                                         */
;/*                                                                   */
;/* DESCRIPTIVE NAME:  RETURN SYSTEM MESSAGE                          */
;/*                                                                   */
;/* COPYRIGHT: (TOP SOURCE FILE ONLY)                                 */
;/*                                                                   */
;/* STATUS: RELEASE 1 LEVEL 0                                         */
;/*                                                                   */
;/* FUNCTION:  RETRIEVES A MESSAGE FROM THE SPECIFIED SYSTEM MESSAGE  */
;/*            AND INSERTS VARIABLE TEXT INTO THE BODY OF THE MESSAGE */
;/*                                                                   */
;/* NOTES:                                                            */
;/*         VARIABLE DATA INSERTION DOES NOT DEPEND ON BLANK          */
;/*         CHARACTER DELIMITERS NOR ARE BLANKS AUTOMATICALLY         */
;/*         INSERTED.                                                 */
;/*                                                                   */
;/*         THE FILENAME INPUT PARAMETER CAN BE OF THE FORM           */
;/*         PATHNAME\FILENAME.                                        */
;/*                                                                   */
;/*         THE MESSAGE FILE WILL BE KEPT OPEN UNTIL THE              */
;/*         PROCESS REQUESTING THE INFORMATION TERMINATES.            */
;/*                                                                   */
;/*    DEPENDENCIES: NONE                                             */
;/*                                                                   */
;/*    RESTRICTIONS: NONE                                             */
;/*                                                                   */
;/*    PATCH LABEL: (TOP SOURCE FILE ONLY)                            */
;/*                                                                   */
;/* ENTRY POINTS:    DOSTRUEGETMESSAGE                                */
;/*                                                                   */
;/* INTERNAL  REFERENCES:                                             */
;/*                                                                   */
;/*                FIND_FILE - OPEN REQUESTED MESSAGE FILE            */
;/*                VAL_FORMAT - VALIDATE MESSAGE FILE FORMAT          */
;/*                VAL_MID_NUM - VALIDATE MESSAGE ID NUMBER           */
;/*                GET_MESSAGE - GET REQUESTED MESSAGE                */
;/* |2A            FOLD_UP - FOLD FILENAME TO UPPERCASE               */
;/* |2A            FILENAME_STRIP - STRIP FILENAME                    */
;/* |2A            COPYRETMSG - COPY ERROR MSG INTO CALLERS BUFFER    */
;/*                                                                   */
;/* EXTERNAL REFERENCES:                                              */
;/*                       DOSOPEN                                     */
;/*                       DOSREAD                                     */
;/*                       DOSCHGFILEPTR                               */
;/* |1<--                 DOSSEMREQUEST                               */
;/*                       DOSSEMLEAVEE                                */
;/* |B<--                 DOSFREESEG                                  */
;/*                       DOSCLOSE                                    */
;/* |B                    DOSALLOCSEG                                 */
;/* |B                    DOSREALLOCSEG                               */
;/* |2A                   DOSGETDBCSEV                                */
;/* |2A                   DOSCASEMAP                                  */
;/*|2A             CHK_LEAD_BYTE - CHECK LEAD BYTE                    */
;/*|2A             RAMFIND - GET RAM MESSAGE                          */
;/*|2A             dosinsmessage - copy message to callers buffer     */
;/*********************** END OF SPECIFICATIONS ***********************/

;***********************************************
; PUBLICS
;***********************************************
        PUBLIC  COUNTRY_CODE                    ; DCR361
        PUBLIC  FROM_GETMSG                     ; DCR361
        PUBLIC  DBCS_YES                        ; DCR361

;***********************************************
; DCR900
;***********************************************
IFNDEF  FamilyAPI                               ; DCR900
        PUBLIC  err_component                   ; DCR900
        PUBLIC  err_filename                    ; DCR900
ENDIF   ;FamilyAPI                              ; DCR900

;***********************************************
; EXTERNALS
;***********************************************
        EXTRN   DOSOPEN:FAR
        EXTRN   DOSREAD:FAR
        EXTRN   DOSCHGFILEPTR:FAR

IFNDEF  FamilyAPI
        EXTRN   DOSFSRAMSEMREQUEST:FAR
        EXTRN   DOSFSRAMSEMCLEAR:FAR
ENDIF   ;FamilyAPI

        EXTRN   DOSFREESEG:FAR
        EXTRN   DOSCLOSE:FAR
        EXTRN   DOSALLOCSEG:FAR
        EXTRN   DOSGETCP:FAR                    ; DCR361

IFNDEF  FamilyAPI
        EXTRN   DOSSEARCHPATH:FAR
        EXTRN   DOSSYSTRACE:FAR
        EXTRN   ReallocSeg:FAR                  ; DCR 704
        EXTRN   DOSGETMESSAGE:FAR               ; DCR900
ELSE
        EXTRN   DOSGETENV:FAR
        EXTRN   DOSREALLOCSEG:FAR               ; DCR 704
        extrn   TXT_MSG_MR_NOT_FOUND:word       ; DCR 704
        extrn   TXT_MSG_MR_READ_ERROR:word      ; DCR 704
        extrn   TXT_MSG_MR_IVCOUNT_ERROR:word   ; DCR 704
        extrn   TXT_MSG_MR_UN_PERFORM:word      ; DCR 704
        extrn   TXT_MSG_MR_CANT_FORMAT:word     ; DCR 704
ENDIF   ;FamilyAPI

        EXTRN   DOSCASEMAP:FAR
        EXTRN   CHECK_DBCS:NEAR
        EXTRN   CHK_LEAD_BYTE:NEAR
        EXTRN   RAMFIND:NEAR
        EXTRN   DOSINSMESSAGE:FAR

        SUBTTL  Includes
        PAGE
;-----------------------------------------------
; INCLUDES HERE
;-----------------------------------------------
        INCLUDE msgfequ.inc             ;EQUATES
        INCLUDE msgfmac.inc             ;MACROS
.XLIST
        INCLUDE error.inc               ;ERROR CODES
        INCLUDE error2.inc              ;new ERROR CODES
        INCLUDE basemaca.inc            ;DOS MACROS
        INCLUDE realmac.inc             ;old macros

        INCLUDE struc30.inc             ;BN002; Structured MACROS

IFNDEF  FamilyAPI
        INCLUDE infoseg.inc             ;symbols for Infoseg (boot drive): protect mode only
        INCL_DOSSEMAPHORES EQU  1
        INCLUDE bsedos.inc
ENDIF   ;FamilyAPI

IFDEF   MMIOPH                          ;@@1
        include perfhook.inc
ENDIF  ;MMIOPH                          ;@@1
.LIST

        SUBTTL  Data and Code Segment Definitions and Local Variables
;***********************************************************************
; THE FOLLOWING DATA SEGMENT DEFINITION IS USED FOR ACCESSING MESSAGES
; TO BE RETURNED WITH AN ERROR CODE.
;***********************************************
        include dc1segs.inc             ;DCR 704

IFNDEF  FamilyAPI
msgseg          segment
ELSE
msgseg          segment para public 'data'
ENDIF   ;FamilyAPI

ValidErrs       Label WORD
        DW      ERROR_OPEN_FAILED            ; error open failed ??
        DW      ERROR_PATH_NOT_FOUND         ; path not found ??
        DW      ERROR_FILE_NOT_FOUND         ; File not found ??
        DW      ERROR_FILENAME_EXCED_RANGE   ; filename not valid
        DW      ERROR_INVALID_NAME           ; filename not valid
        DW      ERROR_ENVVAR_NOT_FOUND       ; dpath not set?
        DW      ERROR_INVALID_ACCESS         ; the rest of these are various
        DW      ERROR_NETWORK_BUSY           ;  acceptable network errors
        DW      ERROR_TOO_MANY_CMDS
        DW      ERROR_ADAP_HDW_ERR
        DW      ERROR_BAD_NET_RESP
        DW      ERROR_UNEXP_NET_ERR
        DW      ERROR_BAD_REM_ADAP
        DW      ERROR_NETNAME_DELETED
        DW      ERROR_BAD_DEV_TYPE
        DW      ERROR_TOO_MANY_SESS
        DW      ERROR_REQ_NOT_ACCEP
        DW      ERROR_INVALID_PASSWORD
        DW      ERROR_VC_DISCONNECTED
        DW      ERROR_REM_NOT_LIST
        DW      ERROR_BAD_NETPATH
        DW      ERROR_DEV_NOT_EXIST
        DW      ERROR_BAD_NET_NAME
        DW      ERROR_REQ_NOT_ACCEP
        DW      ERROR_NETWORK_ACCESS_DENIED
        DW      ERROR_ACCESS_DENIED
ErrCount        EQU ($ - ValidErrs)/2
msgseg          ends

DATA16E segment
        public _EndDATA16                                       ; DCR 704
_EndDATA16      LABEL   BYTE                                    ; DCR 704
DATA16E ends

;***********************************************
; DEFINE THE INSTANCE DATA SEGMENT
;***********************************************
IFNDEF  FamilyAPI
  iseg    SEGMENT
ELSE
  iseg    SEGMENT para public 'data'
ENDIF ; FamilyAPI

    ISEG_CURR_SIZE  DW      0                   ;INITIAL SIZE OF ISEG

    public SIGNATURE_MSGF                       ;DCR361
    SIGNATURE_MSGF  DB      0FFH,'MKMSGF',0     ;MKMSGF SIGNATURE MARK

    CP_DEF_REC      db      (SIZE EXTREC) dup(?)  ; buffer for def record
    file_name       db      (ASCIIZ_LEN+1) dup(?) ;stg for file name        ##2
    temp            db      3 dup(?)            ;temp holder for filename
    file_drive      dw      ?                   ;drive
    file_path       db      '\'                 ;path

IFNDEF  FamilyAPI                               ;DCR900
    err_component   db      'SYS'               ;DCR900
    err_filename    db      'OSO001.MSG',0      ;DCR900
ENDIF ; FamilyAPI

    public ram_file_found                       ;DCR361
    ram_file_found  db      ?
    country_code    dd      0                   ;define country code
    from_getmsg     db      0                   ;define flag
    dbcs_yes        db      0                   ;define flag
                                                ;DCR361

IFNDEF  FamilyAPI
    dpath_str       db      'DPATH',0           ;search path reference (DCR569)

    PUBLIC GetFSRamSem                          ;DCR361
    GetFSRamSem     DOSFSRSEM <14,0,0,0,0,0>    ;intialize to zero, ##1
ELSE
    iSize           DW      OFFSET _EndDATA16   ;size of iseg    DCR 704
    ENVSTRING       DB      'COMSPEC'           ;MATCH ENVIRONMENT STRING FOR BOOT DISK
    ENVSTRING_SIZE  EQU     $-ENVSTRING         ;MATCH STRING SIZE
ENDIF ; FamilyAPI

    PUBLIC SAVED_COUNT, SAVED                   ;@F03

    LAST_SAVE_OFFSET DW     OFFSET SAVED        ;DCR 704
    SAVED_COUNT      DW     0                   ;SAVED FILES COUNTER
    SAVED            SAVE   <>                  ;SAVED FILENAME & HANDLE STRUCTURE

    ISEG_END        EQU     $-ISEG_CURR_SIZE    ;SIZE OF ISEG SEGMENT AT START
iseg    ENDS

;***********************************************************************
; INIT SEGMENT DEFINITION (initialized by MSGINIT)
;***********************************************
IFNDEF  FamilyAPI
initseg SEGMENT
   extrn   GlobalSeg:word                          ; store global segment
   extrn   LocalSeg:word                           ; store local segment
initseg ENDS
ENDIF   ;FamilyAPI

;***********************************************************************
; CODE SEGMENT DEFINITION
;***********************************************
code    SEGMENT
        ASSUME  CS:code, DS:nothing, ES:nothing         ;BC036;

;***********************************************
        PROCEDURE       DOSTRUEGETMESSAGE,FAR
;***********************************************

;***********************************************************************
; CREATE MASK FOR PARAMETERS PASSED ON THE STACK
;***********************************************
        ARGVAR  MSGSEGMENT,DWORD        ;ADDRESS OF MESSAGE SEGMENT
        ARGVAR  MSGLENGTH,DWORD         ;ADDRESS OF LENGTH OF MESSAGE RETURNED
        ARGVAR  FILENAME,DWORD          ;ADDRESS OF MESSAGE FILE NAME
        ARGVAR  MSGNUMBER,WORD          ;MESSAGE NUMBER REQUESTED
        ARGVAR  DATALENGTH,WORD         ;MESSAGE BUFFER LENGTH
        ARGVAR  DATAAREA,DWORD          ;MESSAGE BUFFER ADDRESS
        ARGVAR  IVCOUNT,WORD            ;VARIABLE TEXT COUNT
        ARGVAR  IVTABLE,DWORD           ;VARIABLE TEXT TABLE ADDRESS

;***********************************************************************
; END OF INPUT PARAMETERS
;***********************************************

        SUBTTL   Local variable declarations
        PAGE
        include  vars.inc               ; Local Vars (from stack)
;********************************
        SUBTTL   DosTrueGetMessage Main Routine
        PAGE
;/********************** START OF SPECIFICATIONS *********************/
;/* SUBROUTINE NAME:  DOSTRUEGETMESSAGE                              */
;/*                                                                  */
;/* DESCRIPTIVE NAME:  RETURN SYSTEM MESSAGE                         */
;/*                                                                  */
;/* FUNCTION: RETRIEVES A MESSAGE FROM THE SPECIFIED SYSTEM MESSAGE  */
;/*           FILE AND INSERTS VARIABLE INFORMATION INTO THE BODY OF */
;/*           THE MESSAGE.                                           */
;/*                                                                  */
;/* NOTES:                                                           */
;/*         VARIABLE DATA INSERTION DOES NOT DEPEND ON BLANK         */
;/*         CHARACTER DELIMITERS NOR ARE BLANKS AUTOMATICALLY        */
;/*         INSERTED.                                                */
;/*                                                                  */
;/*         THE FILENAME INPUT PARAMETER CAN BE OF THE FORM          */
;/*         PATHNAME\FILENAME.                                       */
;/*                                                                  */
;/*         THE MESSAGE FILE WILL BE KEPT OPEN UNTIL THE             */
;/*         PROCESS REQUESTING THE INFORMATION TERMINATES.           */
;/*                                                                  */
;/*         Entire function rewritten for J200380 (;BN037;)          */
;/*                                                                  */
;/* RESTRICTIONS: NONE                                               */
;/*                                                                  */
;/* ENTRY POINT:  DOSTRUEGETMESSAGE                                  */
;/*    LINKAGE:   CALL FAR                                           */
;/*                                                                  */
;/* INPUT:  IVTABLE  =  VARIABLE TEXT TABLE ADDRESS  (DOUBLE WORD)   */
;/*         IVCOUNT  =  VARIABLE TEXT COUNT  (WORD)                  */
;/*         DATAAREA =  MESSAGE BUFFER ADDRESS  (DOUBLE WORD)        */
;/*         DATALENGTH = MESSAGE BUFFER LENGTH  (WORD)               */
;/*         MSGNUMBER = MESSAGE ID NUMBER  (WORD)                    */
;/*         ASCIIZ FILENAME = FILENAME WHERE MESSAGE CAN BE FOUND    */
;/*                           (DOUBLE WORD)                          */
;/*         MSGLENGTH = ACTUAL MESSAGE LENGTH RETURNED (DOUBLE WORD) */
;/*                                                                  */
;/* EXIT-NORMAL:  AX = 0                                             */
;/*               DATAAREA POINTS TO MESSAGE BUFFER WHICH CONTAINS   */
;/*               RETRIEVED MESSAGE.                                 */
;/*               MSGLENGTH POINTS TO ACTUAL LENGTH OF THE MESSAGE   */
;/*               RETURNED.                                          */
;/*                                                                  */
;/* EXIT-ERROR:   AX = RETURN CODE                                   */
;/*                                                                  */
;/*    ERROR_FILE_NOT_FOUND      File not found                      */
;/*    ERROR_MR_MSG_TOO_LONG     Message too long for buffer         */
;/*    ERROR_MR_MID_NOT_FOUND    Message ID number not found         */
;/*    ERROR_MR_INV_MSGF_FORMAT  Invalid message file format         */
;/*    ERROR_MR_INV_IVCOUNT      Invalid insertion variable count    */
;/*    ERROR_MR_UN_PERFORM       Unable to perform requested function*/
;/*                                 - No more handles                */
;/*                                 - Read or CRC error              */
;/*                                 - Unable to allocate storage     */
;/*                                 - Access denied                  */
;/*                                 - Drive not ready                */
;/*                                                                  */
;/* EFFECTS:  NONE                                                   */
;/*                                                                  */
;/* INTERNAL REFERENCES:                                             */
;/*    ROUTINES:   FIND_FILE - OPEN REQUESTED MESSAGE FILE           */
;/*                     VAL_FORMAT - VALIDATE MESSAGE FILE FORMAT    */
;/*                     VAL_MID_NUM - VALIDATE MESSAGE ID NUMBER     */
;/*                GET_MESSAGE - GET REQUESTED MESSAGE               */
;/*                COPYRETMSG - COPY ERROR MESSAGE INTO CALLERS BUFF */
;/*                                                                  */
;/* EXTERNAL REFERENCES:                                             */
;/*    ROUTINES:          DOSGETDBCSEV                               */
;/*                       DOSFREESEG                                 */
;/*                       dosinsmessage                             */
;/*********************** END OF SPECIFICATIONS **********************/
IFNDEF  FamilyAPI
        ENTERPROC                       ;SETUP BP
ELSE
        RealEnter                       ;setup bp
ENDIF   ;FamilyAPI

        SAVE_CALLER                     ;save environment
        CLD                             ;CLEAR DIRECTION FLAG
;
;***DT  preDOSGETMESSAGE - DosGetMessage pre-invocation trace point
;
;    TRACE MINOR = <RAS_DC1_PRE_DOSGETMESSAGE>,
;          TP=.PREGETMSG,
;          TYPE=(PRE,API),
;          GROUP = MSG,
;          DESC="(OS) DosGetMessage Pre-Invocation",
;          FMT="MsgNumber = %PW",
;          FMT="Filename = %PS",
;          MEM=(RSS+BP+18,DIRECT,2),
;          ASCIIZ=(RSS+BP+14,INDIRECT,260),

IFNDEF  FamilyAPI
;****************
;       Trace hook PreInvocation - DosGetmessage
;
        push    TraceCode_PreGetMessage
        push    filenameh
        push    filenamel
        push    msgnumber
        call    MSGTRACE
;*****************
ENDIF   ;FamilyAPI




        PUBLIC PREGETMSG
PREGETMSG:
        xor     ax,ax                 ;initialization
        MOV     SYS_ERROR,ax            ;no err
        MOV     SAV_ERROR,ax            ;no err
        MOV     MSR_ERROR,ax            ;no err
        MOV     free_save_struc,ax      ;usused "SAVE" area     @f03
        mov     subfile_flag,ah         ;not subfile
        MOV     RAM_MSG_FOUND,ah        ;msg not in RAM
        mov     old_file,ah             ;not in SAVE.xxx
        mov     default_root,ah         ;not default
        mov     got_ram_sem,ah          ;no semaphore yet
        MOV     IS_DBCS,ah              ;0 = NOT DBCS
        mov     msg_id,ah               ;no msg id returned
        mov     work_root,ah            ;DONT CLOSE RootFile
        mov     work_subf,ah            ;DONT CLOSE Sub File

        les     di,msglength          ;length
        stosw                           ;returned

        MOV     ax,iseg                 ;SET
        MOV     ds,ax                   ; INSTANCE
        MOV     es,ax                   ;  SEGMENT
        assume  ds:iseg, es:iseg        ;   ADDRESSABILITY

        .if     <[ivcount] a 9>         ;max substitution parm count
          mov     sys_error,ERROR_MR_INV_IVCOUNT  ;too high
          jmp     clean_up                        ; is an error
        .endif

;*************************************************
; CALL DOSGETDBCSEV - GET DBCS ENVIRONMENT VECTOR;
;
        mov     from_getmsg,1           ;get system default data
        mov     word ptr country_code,0
        mov     word ptr country_code+2,0

        CALL    CHECK_DBCS              ;GET DBCS ENVIRONMENT VECTOR
        .if     <C>                     ;Carry flag
          MOV     IS_DBCS,1               ;is DOUBLE BYTE
        .endif

        .if     <[iseg_curr_size] eq 0>    ;if 1st time through
          MOV     ISEG_CURR_SIZE,ISEG_END    ;set Instance Segment size
        .endif

;
;       GET CURRENT PROCESS CODE PAGE
;
        mov     ax,CP_LENGTH            ; set length for cplist
        push    ax
        lea     ax,CPLIST               ; set cplist
        push    ss
        push    ax
        lea     ax,CP_RTNLNG            ; set returned data length
        push    ss
        push    ax
        call    DOSGETCP

;
;       CALL FIND_FILE - OPEN REQUESTED MESSAGE FILE;
;
public look_for_file
look_for_file:
        xor     ax,ax                   ; initialize
        mov     exthd_cnt,ax              ; def record count
        mov     exthd_flg,al              ; def record flag
        mov     default_root,al           ; default to root file
        mov     sub_handle,ax             ; sub_handle
        mov     subfile_flag,al           ; not a sub_file

        CALL    FIND_FILE

        .if     <[sys_error] EQ error_file_not_found>   ;BN039;
          mov     sys_error,0           ;look again     ;BN039;
          mov     word ptr CPLIST,0     ;default CP     ;BN039;
          call    find_file             ;may be in RAM  ;BN039;
        .endif                                          ;BN039;

        .if     <[ram_msg_found] eq 1>  ;Message found in RAM
          jmp     call_ins_msg            ;go insert message
        .elseif <[sys_error] ne 0>      ;Any error found
          jmp     clean_up                ;go clean up
        .elseif <[old_file] ne 1>       ;if processing new file
          CALL    VAL_FORMAT              ;Validate the format
          .if     <c>                     ;in case of error
            jmp     clean_up                ;we're outta here
          .else
            mov     al,work_hndl          ;copy "OPEN/SAVED" state flag
            mov     work_root,al
          .endif
        .endif

;
;       Save ROOT FILE information
;
PUBLIC chkmore
chkmore:
        mov     ax,MSGF_HEADER.VERSION          ;version number
        mov     ROOT_VERSION,ax

        mov     ax,MSGF_HEADER.MSG_COUNT        ;root message count
        mov     ROOT_MSGCNT,ax

        mov     ax,MSGF_HEADER.BASE_MID         ;root message base ID
        mov     ROOT_BASEID,ax

        mov     al,MSGF_HEADER.INDICATOR        ;root indicator
        mov     ROOT_INDICATOR,al

        mov     ax,word ptr MSGF_HEADER.EXT_HEADER    ;extended header offset
        mov     word ptr ROOT_EXT_HEADER,ax
        mov     ax,word ptr MSGF_HEADER.EXT_HEADER+2
        mov     word ptr ROOT_EXT_HEADER+2,ax

        xor     si,si                           ;clear index
        mov     cx,component_length             ;set component length

        .repeat                                  ;Save component ID
          mov     al,MSGF_HEADER.COMPONENT_ID[si]  ;
          mov     ss:component[si],al              ;
          mov     ss:ROOT_COMPONENT[si],al         ;
          inc     si                               ;
        .loop

;
;       See if ROOT FILE contains Code Page data
;
        mov     ax,word ptr MSGF_HEADER.CP_DATA  ;CP data offset
        mov     dx,MSGF_HEADER.VERSION           ;file version

        .if     <dx NE 2> OR            ;Old format file
        .if     <ZERO ax>               ;or no code page data
          xor     ax,ax                       ;use
          mov     word ptr country_code,ax    ; default
          mov     word ptr country_code+2,ax  ;  code
          jmp     handle_found                ;   page
        .endif                                ;    & current file

        .if     <[old_file] eq 1> AND   ;if file from saved iseg
        .if     <[msr_error] eq 0>      ;& code page matches            ;BN038;
          jmp     handle_found            ;handle found processing
        .endif

;
;       Look for matching code page (if any)
;
        lea     si,CP_DEF_REC.REC_CP_ID   ; get address
        xor     bx,bx                     ; clear index
        mov     cx,CP_DEF_REC.REC_CNT_CP  ; get code page count
        .if     <NONZERO cx>
          .if     <cx A CP_ALL>                   ;validate CP max
            mov     SYS_ERROR,ERROR_MR_INV_MSGF_FORMAT  ; flag error
            jmp     clean_up                            ; & exit
          .endif
          .repeat
            mov     ax,es:[si][bx]              ; get code page
            .if     <ax EQ <word ptr CPLIST>>   ; If matching Code Page
              mov     word ptr COUNTRY_CODE+2,ax  ; save current code page
              mov     ax,CP_DEF_REC.REC_CNTY_ID
              mov     word ptr COUNTRY_CODE,ax    ; save current country ID
              jmp     handle_found                ; get message text
            .endif
            inc     bx                      ; bump up index(2 bytes)
            inc     bx                      ; bump up index
          .loop
        .endif

;***********************************************
;       Look for extended header data
;
PUBLIC chk_ext_hdrs
chk_ext_hdrs:
        mov     exthd_flg,1             ; set read hdr flag
        mov     ax,word ptr ROOT_EXT_HEADER    ; extended header OFFSET
        mov     word ptr exthd_ptr,ax            ;
        mov     bx,word ptr ROOT_EXT_HEADER+2    ;
        mov     word ptr exthd_ptr+2,bx          ;

        .if     <ZERO ax> AND           ;if no extended header data
        .if     <ZERO bx>                 ;
          jmp     default_to_root         ; try root file
        .endif

        push    HANDLE                  ; set handle
        push    bx                      ; set distance
        push    ax
        xor     dx,dx                   ;function = 0
        push    dx                        ; from beginning
        lea     ax,NEW_POINTER          ; set new pointer
        push    ss
        push    ax
        CALL    DOSCHGFILEPTR
        .if     <NONZERO ax>                    ;if I/O errpr
          mov     SYS_ERROR,ERROR_MR_UN_ACC_MSGF  ; flag error
          jmp     clean_up                        ; & cleanup
        .endif

;
;       Read the Extended Header Data
;
        push    HANDLE                  ; file handle
        lea     ax,CP_EXT_HEADER        ; get buffer ptr
        push    ss                        ;
        push    ax                        ;
        mov     dx,SIZE EXT_HDR         ; buffer length
        push    dx                        ;
        lea     cx,RESULT               ; result ptr
        push    ss                        ;
        push    cx                        ;
        CALL    DOSREAD

        .if     <NONZERO ax> OR         ; I/O error
        .if     <[result] NE dx>        ; or wrong length read
          mov     SYS_ERROR,ERROR_MR_UN_ACC_MSGF  ; set error code
          jmp     clean_up                        ; & exit
        .endif

        add     word ptr exthd_ptr,SIZE EXT_HDR
        adc     word ptr exthd_ptr+2,0
        mov     cx,CP_EXT_HEADER.EXT_NUM_DEF_REC  ; get # of def recs
        .if     <ZERO cx>               ; If no DEF records?
          jmp     default_to_root         ; try root file
        .endif


;***********************************************
;       Read the next Definition Record
;
public chkcp10
chkcp10:
        mov     ax,iseg                 ;GET INSTANCE SEGMENT ADDRESSABILITY
        mov     es,ax                   ;INTO ES
        assume  es:iseg

        push    HANDLE                  ; set file handle
        lea     ax,CP_DEF_REC           ; buffer ptr
        push    es                        ;
        push    ax                        ;
        mov     dx,SIZE EXTREC          ; buffer length
        push    dx                        ;
        lea     bx,RESULT               ; result ptr
        push    ss                        ;
        push    bx                        ;
        CALL    DOSREAD

        .if     <NONZERO ax> OR         ; I/O error
        .if     <[result] NE dx>        ; or wrong length read
          mov     SYS_ERROR,ERROR_MR_UN_ACC_MSGF  ; set error code
          jmp     clean_up                        ; and exit
        .endif

        add     word ptr exthd_ptr,SIZE EXTREC
        adc     word ptr exthd_ptr+2,0
        mov     dx,cx                   ; save # of def records
        lea     si,CP_DEF_REC.REC_CP_ID ; get ptr of first code page
        xor     bx,bx                   ; clear index
        mov     cx,CP_DEF_REC.REC_CNT_CP          ; get code page count
        or      cx,cx                   ; check code page count
        jz      chkcp15

        .if     <cx A CP_ALL>           ;more than supported
          mov     SYS_ERROR,ERROR_MR_UN_ACC_MSGF  ;set error code
          jmp     clean_up                        ; & exit
        .endif

        .repeat
          mov     ax,es:[si][bx]        ; get next code page
          cmp     ax,word ptr CPLIST    ; compare current process cp ID
          je      chkcp14                 ; match - open sub-message file
          inc     bx                      ; miss - bump index
          inc     bx
        .loop

;
;   GET NEXT DEFINITION RECORD HERE
;
PUBLIC chkcp15
chkcp15:
        mov     cx,dx                   ; restore # of def records
        dec     cx                      ; down # of def records by 1
        jnz     chkcp10                   ; continue with extendeds
        jmp     default_to_root           ; or default to root


;
; ***** CALL SUB-MESSAGE FILE HERE
;
public chkcp14
chkcp14:
        mov     word ptr COUNTRY_CODE+2,ax  ; save current code page
        mov     exthd_cnt,dx                ; & defrec count

        mov     subfile_flag,1              ; Look for as sub_file
        lea     di,CP_DEF_REC.REC_FILENAME    ;
        CALL    FIND_FILE                     ;

        .if     <[ram_msg_found] eq 1>      ;Message in RAM
          jmp     call_ins_msg                ;do insert
        .elseif <[MSR_ERROR] NE 0> OR       ;file found, not CodePage   ;BN038;
        .if     <[SYS_ERROR] EQ error_file_not_found>                   ;BC038;
          jmp     short chkcp16               ;next subfile
        .elseif <[old_file] ne 1>           ;if processing new file
          CALL    VAL_FORMAT                  ;Validate the format
          jc      chkcp16                       ;oops - next subfile
          mov     al,work_hndl                ;copy "OPEN/SAVED" state flag
          mov     work_subf,al
        .endif

        mov     dx,CP_DEF_REC.REC_CNTY_ID   ; save country ID
        mov     word ptr COUNTRY_CODE,dx      ;
        jmp     short handle_found          ; & process file


;***********************************************
;***********************************************
;       File/Message not found, continue Definition Record Processing
;
PUBLIC chkcp16
chkcp16:
        .if     <[exthd_flg] EQ 0>      ; Was Ext Header record processed
          jmp     chk_ext_hdrs            ; no - go read it
        .endif

        mov     dx,exthd_cnt            ; restore # of def records remainder
        .if     <ZERO dx>               ; if no more to check
          jmp     short default_to_root   ; default to root
        .endif

        mov     SYS_ERROR,0             ; clear error code
        push    HANDLE                  ; handle
        mov     dx,word ptr exthd_ptr+2 ; offset
        push    dx                        ; HO word
        mov     ax,word ptr exthd_ptr     ;
        push    ax                        ; LO word
        xor     bx,bx                   ; move type
        push    bx                        ; (from beginning)
        lea     ax,NEW_POINTER          ; set new pointer
        push    ss                        ;
        push    ax                        ;
        CALL    DOSCHGFILEPTR
        .if     <NONZERO ax>            ; if I/O error
          mov     SYS_ERROR,ERROR_MR_UN_ACC_MSGF  ; set flag
          jmp     clean_up                        ; & exit
        .endif

        mov     dx,exthd_cnt            ; restore it
        jmp     chkcp15


;***************************************
;       Cant find message in normal processing, default to ROOT file
;
public  default_to_root
default_to_root:
        xor     ax,ax
        mov     word ptr CPLIST,ax      ; default Code Page
        mov     subfile_flag,al         ; no mo SUBFILE
        mov     default_root,1          ; is de root

        mov     ax,HANDLE               ; Root file handle
        mov     VMSG_HANDLE,ax            ;
        mov     ax,ROOT_MSGCNT          ; MESSAGE COUNT
        mov     VMSG_MSGCNT,ax            ;
        mov     ax,ROOT_BASEID          ; BASE ID
        mov     VMSG_BASEID,ax            ;
        mov     ax,ROOT_VERSION         ; VERSION NUMBER
        mov     VMSG_VERSION,ax           ;
        mov     al,ROOT_INDICATOR       ; INDICATOR
        mov     VMSG_INDICATOR,al         ;
        mov     ax,word ptr ROOT_EXT_HEADER     ; Offset to EXT Header
        mov     word ptr VMSG_EXT_HEADER,ax       ;
        mov     ax,word ptr ROOT_EXT_HEADER+2     ;
        mov     word ptr VMSG_EXT_HEADER,ax       ;


;***********************************************
;       WE'VE GOT THE FILE OPENED
;             Since CountryCode may have changed, check again for DBCS
;
public  handle_found
handle_found:
        MOV     FROM_GETMSG,1           ;set from DosGetMessage
        CALL    CHECK_DBCS              ;GET DBCS ENVIRONMENT VECTOR
        .if     <C>                       ;
          mov     ah,1                    ; is DBCS
        .else                             ;
          xor     ah,ah                   ; is SBCS
        .endif                            ;
        MOV     IS_DBCS,ah              ;DosGetMessage flag
        mov     dbcs_yes,ah             ;DosInsMessage flag

;
;       Validate the message number
;
        CALL    VAL_MID_NUM
        .if     <C>                     ;if message not found
          cmp     default_root,1          ;is it default/error path
          jne     chkcp16                   ;NO - try next extended header
          jmp     clean_up                  ;YES- all done
        .endif


;
;       Message number is valid: read it in
;
PUBLIC go_get_message
go_get_message:

        CALL    GET_MESSAGE
        ljc     clean_up                ;IF READ FAILED GET OUT

        MOV     DS,MSG_SEL              ;-> 1st text byte
        MOV     SI,1                      ; (after error class)

        MOV     BX,MSG_NUMBER_LEN       ;BX = text length
        DEC     BX                        ; (after error class)


;***************************************
;       Message found, go do text inserts as needed
;               DS:SI -> Text
;               BX     = Length of Text
;
public call_ins_msg
call_ins_msg:
        xor     ax,ax                   ;reset flags    @F04
        mov     sys_error,ax             ;              @F04
        mov     msr_error,ax             ;              @F04

        mov     al,byte ptr [si] [bx] -1  ;get last byte of text
        .if     <ZERO al> or              ; if NULL
        .if     <al EQ 1ah>               ; or Ctl-Z   (EOF)
          dec     bx                        ; back it out
        .endif

;
;       Check Message Class (for ? or E or W)
;
        mov     al,byte ptr [si-1]        ;get message class
        .if     <al EQ UNKNOWN_CLASS>             ; if "Unknown"
          mov     sys_error, error_mr_mid_not_found ; tag the error
          jmp     free_msg_sel                        ;
        .endif

        .if     <al EQ ERROR_CLASS> OR  ;If "Error"
        .if     <al EQ WARNING_CLASS>   ;or "Warning"
          mov     msg_id,1                ;set flag to return msg id
          mov     ax,msgnumber            ;copy msg header
          call    copymsghd               ; into caller buffer
          cmp     sys_error,0
          jnz     free_msg_sel
        .endif

;
;       copy message text into callers buffer
;
        mov     ax,ivtableh             ;address of ivtable
        push    ax                        ;
        mov     ax,ivtablel               ;
        push    ax                        ;
        push    ivcount                 ;ivcount
        push    ds                      ;address of msginput
        push    si                        ;
        push    bx                      ;msginlength
        mov     ax,dataareah            ;address of dataarea
        push    ax                        ;
        mov     ax,dataareal              ;
        push    ax                        ;
        push    datalength              ;datalength
        mov     ax,msglengthh           ;address of msglength
        push    ax                        ;
        mov     ax,msglengthl             ;
        push    ax                        ;

        CALL    DosInsMessage
        mov     sys_error,ax

        .if     <[msg_id] eq 1>         ;if return msg id
          les     di,msglength            ;get message length
          mov     ax,word ptr es:[di]       ;
          add     ax,9                    ;adjust to reflect 9 byte header
          stosw                           ;store message length
        .endif

free_msg_sel:
        .if     <[ram_msg_found] eq 0>  ;if not from RAM
          push    msg_sel                 ;free allocated
          call    dosfreeseg              ; message buffer
        .endif


;***********************************************
;       Clean up time: look for MAJOR problems
;
PUBLIC  CLEAN_UP
CLEAN_UP:
        .if     <[work_root] ne 0>      ;if Open & NOT Saved
          push    handle                  ;close
          call    DOSCLOSE                ; ROOT
          mov     work_root,0             ;  File
        .endif

        .if     <[work_subf] ne 0>      ;if Open & NOT Saved
          push    sub_handle              ;close
          call    DOSCLOSE                ; Sub
          mov     work_subf,0             ;  File
        .endif

        mov     ax,sys_error
        .if     <NONZERO ax> AND                ;if error
        .if     <ax NE ERROR_MR_MSG_TOO_LONG>   ; other than TOO LONG
          MOV     SAV_ERROR,AX                    ;save error
          MOV     MSR_ERROR,AX                      ;
          mov     sys_error,0                     ;get MSR error msg
          CALL    COPYRETMSG                        ;
          .if     <[SYS_ERROR] eq 0>              ;if NO NEW error
            MOV     AX,MSR_ERROR                    ;restore
            MOV     SAV_ERROR,AX                    ; old
            MOV     SYS_ERROR,AX                    ;  error
          .endif
        .endif


IFNDEF  FamilyAPI
;
;       Release the Semaphore
;
        .if     <[got_ram_sem] ne 0>    ; If we got a semaphore
          mov     got_ram_sem,0           ; clear flag
          PUSH    iseg                    ; release the sucker
          PUSH    offset GetFSRamSem        ;
          CALL    DOSFSRAMSEMCLEAR          ;
        .endif
ENDIF   ;FamilyAPI

        MOV     AX,SYS_ERROR            ;GET ERROR CODE FOR RETURN

;
;***DT  postDOSGETMESSAGE - DosGetMessage post-invocation trace point
;
;    TRACE MINOR = <RAS_DC1_POST_DOSGETMESSAGE>,
;          TP=.POSTGETMSG,
;          TYPE=(POST,API),
;          GROUP = MSG,
;          DESC="(OS) DosGetMessage Post-Invocation",
;          FMT="Return Code = %W",
;          FMT="Message Length = %PW"
;          REGS=(AX),
;          MEM=(RSS+BP+10,INDIRECT,2),

IFNDEF  FamilyAPI
;
;       Trace hook PostInvocation - DosGetmessage
;
        push    TraceCode_PostGetMessage
        push    0
        lds     si,msglength
        mov     bx,[si]
        push    bx
        push    ax
        call    MSGTRACE
ENDIF   ;FamilyAPI


        PUBLIC POSTGETMSG
POSTGETMSG:

        RESTORE_CALLER  26
DOSTRUEGETMESSAGE   ENDP
;********************************
        SUBTTL  Find_File Routine
        PAGE
;/********************** START OF SPECIFICATIONS *********************/
;/* SUBROUTINE NAME:  FIND_FILE                                      */
;/*                                                                  */
;/* DESCRIPTIVE NAME:  OPEN REQUESTED MESSAGE FILE                   */
;/*                                                                  */
;/* FUNCTION: OPEN REQUESTED MESSAGE FILE AND RETURN FILE HANDLE.    */
;/*           FOLDS FILENAME TO UPPERCASE.                           */
;/*                                                                  */
;/* NOTES:  CALLS RAMFIND TO GET RAM MESSAGE                         */
;/*                                                                  */
;/*         Entire function rewritten for J200380 (;BN037;)          */
;/*                                                                  */
;/* RESTRICTIONS: NONE                                               */
;/*                                                                  */
;/* ENTRY POINT:  FIND_FILE                                          */
;/*    LINKAGE:   CALL NEAR                                          */
;/*                                                                  */
;/* INPUT:  ES:DI --> FILENAME                                       */
;/*                                                                  */
;/* EXIT-NORMAL:  file handle in HANDLE                              */
;/*               CRFL = 0                                           */
;/*                                                                  */
;/*    EXIT-ERROR:   ERROR CODE IN SYS_ERROR                         */
;/*                  CRFL = 1                                        */
;/*                                                                  */
;/*    ERROR_FILE_NOT_FOUND      File not found                      */
;/*    ERROR_MR_UN_PERFORM       Unable to perform requested function*/
;/*                                 - No more handles                */
;/*                                 - Read or CRC error              */
;/*                                 - Unable to allocate storage     */
;/*                                 - Access denied                  */
;/*                                 - Drive not ready                */
;/*                                                                  */
;/* EFFECTS:  NONE                                                   */
;/*                                                                  */
;/* INTERNAL REFERENCES:                                             */
;/*    ROUTINES:          FILENAME_STRIP - STRIP FILENAME            */
;/*                                                                  */
;/* EXTERNAL REFERENCES:                                             */
;/*    ROUTINES:          DOSOPEN                                    */
;/*                       RAMFIND                                    */
;/*                       DOSALLOCSEG                                */
;/*********************** END OF SPECIFICATIONS **********************/
PUBLIC FIND_FILE
FIND_FILE       PROC    NEAR

;@117349   Since we are using variables in the instance data segment,
;@117349   we need to synchronize access to them by multiple threads
;@117349   within the same process.

IFNDEF  FamilyAPI                                                  ;@117349
        .if     <[got_ram_sem] eq 0>    ; if this is 1st semaphore ;@117349
          mov     ax , 0FFFFh                                      ;@117349
          mov     got_ram_sem,al          ; drt flag               ;@117349
          push    iseg                    ; seg GetFSRamSem        ;@117349
          push    offset GetFSRamSem      ; off GetFSRamSem        ;@117349
          push    ax                      ; Indefinite wait        ;@117349
          push    ax                        ; 0FFFFFFFFh           ;@117349
          call    DOSFSRAMSEMREQUEST      ; GET FSRAM SEMAPHORE    ;@117349
        .endif                                                     ;@117349
ENDIF   ;FamilyAPI                                                 ;@117349

        .if     <[subfile_flag] NE 1>   ;if not a subfile
          LES     DI,FILENAME             ;ES:DI -> INPUT FILENAME
        .endif

;
;       CALCULATE FILENAME LENGTH
;
        xor     ax,ax
        MOV     OLD_FILE,al
        mov     msr_error,ax            ;reset CP error check           ;BN038;

        MOV     DX,DI                   ;SAVE INPUT FILENAME OFFSET
        MOV     CX,ASCIIZ_LEN           ;CX = MAX ASCIIZ LEN
        REPNE   SCASB                   ;SCAN TIL EOSTRING (AL=0)
        MOV     BX,ASCIIZ_LEN           ;GET MAX ASCIIZ LEN
        SUB     BX,CX                   ;BX: STRING LENGTH

;
;       CAP filename and strip off PATH
;
        .if     <[subfile_flag] ne 0>   ;       ;check opened message file
          push    es                              ;@4 set correct segment
          pop     ds
          mov     si,dx                           ;set correct offset
        .else                                   ;now ds:si points to filename
          lds     si,filename             ; ds:si -> input filename
        .endif

        mov     ax,iseg                 ; es:di point to filename storage ##2
        mov     es,ax
        lea     di,file_name            ; es:di point to filename
        mov     cx,bx                   ; get length to copy
        rep     movsb                   ; copy till cx=0

        lea     dx,file_name            ; es:dx point to start of filename ##2
        CALL    FOLD_UP                 ; Fold filename to upper case
        .if     <[sys_error] NE 0>        ;
          JMP     END_FIND_FILE           ; exit if error
        .endif                            ;

        CALL FILENAME_STRIP   ; strip filename out of input string

;
;       Look in RAM for the message (maybe)
;
public look_in_ram
look_in_ram:
        .if     <[msgsegmenth] NE 0>            ;if Msg Segment exists
          lea     ax,component            ;addr Component ID Field
          push    ss                        ; seg
          push    ax                        ; off
          push    es                      ;addr of Filename
          push    di                        ;
          push    msgsegmenth             ;addr of Message segment
          push    msgsegmentl               ;
          push    msgnumber               ;message number
          lea     ax,CPLIST               ;addr CodePage Info
          push    ss                        ; seg
          push    ax                        ; off

          CALL    RAMFIND                 ;LOOK IN RAM Segment
          .if     <NC>                    ;If found in RAM (Carry off)
            MOV     RAM_MSG_FOUND,1         ; set IN_RAM flag
            MOV     BX,CX                   ; save msg length
            JMP     END_FIND_FILE           ; & exit
          .endif
        .endif


;
;       Message not in RAM, search the saved entries for this file
;
public CHK_MSG_FILE
CHK_MSG_FILE:

;;;@117349IFNDEF  FamilyAPI
;;;@117349        .if     <[got_ram_sem] eq 0>    ; if this is 1st semaphore
;;;@117349          mov     ax , 0FFFFh
;;;@117349          mov     got_ram_sem,al          ; drt flag
;;;@117349          push    iseg                    ; seg GetFSRamSem
;;;@117349          push    offset GetFSRamSem      ; off GetFSRamSem
;;;@117349          push    ax                      ; Indefinite wait
;;;@117349          push    ax                        ; 0FFFFFFFFh
;;;@117349          call    DOSFSRAMSEMREQUEST      ; GET FSRAM SEMAPHORE
;;;@117349        .endif
;;;@117349ENDIF   ;FamilyAPI

        MOV     AX,iseg                 ;GET INSTANCE SEGMENT ADDRESSABILITY
        MOV     DS,AX                   ;INTO DS
        assume  ds:iseg

        MOV     AX,SAVED_COUNT          ;LOAD NUMBER OF FILENAMES SAVED
        .if     <ZERO ax>
          jmp     short NO_MATCH        ;try DASD if none were save
        .endif
        LEA     SI,SAVED                ;DS:SI -> FIRST SAVED.FILENAME
        MOV     DI,DX                   ;RESET INPUT FILENAME POINTER

;
;       Look for matching CodePage data
;
MATCH_LOOP:
        MOV     CX,BX                   ;GET LENGTH TO COMPARE
        REPE    CMPSB                   ;COMPARE FILENAMES
        JNE     FILES_DONT_MATCH        ;COMPARE NEXT FILENAME

        push    si                              ;save si
        push    bx                              ;save bx
        push    cx                              ;save cx
        push    ax                              ;save ax

        sub     si,bx                           ;point to beginning of filename
        mov     ax,save.cp_data_s[si]           ;check cp_data saved value
        or      ax,ax                           ;compatible reason
        jz      restorsi                          ;use file if no data

        mov     cx,save.cpcount_s[si]           ;get code page counts
        xor     bx,bx                           ;clear bx
        cmp     bx,word ptr CPLIST              ;is current cp = 0
        jz      restorsi

PUBLIC cmploop                          ;@1 SDD
cmploop:
        mov     ax,save.cp_s[si][bx]            ;get code page
        cmp     ax,word ptr CPLIST              ;compare current code page
        jz      restorsi                        ;yes, restore si
        or      ax,ax                           ;@2 is the codpage of the file 0
        jz      restorsi                        ;@2then call it fine
        inc     bx                              ;no, bump index
        inc     bx
        loop    cmploop                         ;get next page

        ;                                                              ;BN038;
        ; File found, but NO Code Page match                           ;BN038;
        ;                                                              ;BN038;
        mov     msr_error,1                     ;set CP mismatch check ;BN038;

restorsi:
        pop     ax                              ;restore ax
        pop     cx                              ;restore cx
        pop     bx                              ;restore bx
        pop     si                              ;restore si
        JMP     GET_SAVED_HANDLE                ;MATCH !


FILES_DONT_MATCH:
        MOV     DI,DX                           ;RESET INPUT FILENAME POINTER
        ADD     SI,CX                           ;GET SI TO POINT TO START
        SUB     SI,BX                           ;OF CURRENT SAVED.FILENAME
                                                ;SI=SI-(BX-CX)
        .if     <<byte ptr save.filename_s[si]> eq 0>   ;@F03
          mov     free_save_struc,si                    ;@F03 Struct unused
        .endif                                          ;@F03

        DEC     AX                              ;MORE  SAVED.FILENAMES ?
        JZ      NO_MATCH                        ;NONE LEFT TO COMPARE
        MOV     SI,SAVE.NEXT_SAVE[SI]           ;GET NEXT SAVED.FILENAME
        JMP     MATCH_LOOP                      ;DO AGAIN


NO_MATCH:
;|B<-- IF FILENAME <> SAVED FILENAME THEN
;       call do_open - open file user entered
;       if fail then
;          call filename_strip;
;          call dosallocseg - allocate buffer for search path;
;          call dossearchpath - get path\filename;
;          call do_open - open file;
;             if fail (file_not_found) then
;                exit with error;
;             endif;
;          endif;
;          call getbootroot - get system boot drive letter;
;          copy system boot drive letter and filename into buffer;
;          call do_open - open file;
;          if fail (file_not_found) then
;             exit with error;
;          endif;
;       endif;
;       bx=length of asciiz string, dx=start of string, es=selector for string
;

        mov     ax,iseg         ; es:di point to filename buffer ##2
        mov     es,ax
        lea     di,file_name
        call    do_open                 ; open file

        call    test_open_err           ; check for errors
        jc      chk_err

IFNDEF  FamilyAPI
        mov     sav_error, ax           ; save old error
ENDIF  ;FamilyAPI

        call    filename_strip          ; es:di points to filename only
        mov     dx,di                   ; save offset to filename only

IFDEF  FamilyAPI                        ; es:di points to filename only
        lea     ax, file_name           ; ##2
        cmp     di, ax                  ; see if user entered filename only
        jz      getboot                 ; yes, skip to try boot
        call    do_open                 ; try opening file in current directory
ELSE
        call    open_dpath              ; search & open file
ENDIF ;FamilyAPI

        call    test_open_err           ; check for errors
        jc      chk_err

PUBLIC getboot                          ;@1 SDD
getboot:
        call    getbootroot          ; get system boot drive letter

IFDEF   FamilyAPI
        or      cx,cx                   ; did we find a drive letter ?
        jnz     tryboot                 ; no so go stuff 'C:' instead
        mov     cx, ':C'                ; try 'C:'
ENDIF   ; FamilyAPI

tryboot:
        call    xfer_filename           ; get buffer for filename only
                                        ; and drive + filename into it
        call    do_open                 ; open file
        mov     cx, word ptr ds:temp    ; restore filename
        mov     es:[di], cx             ; restore first 2 bytes
        mov     cl, ds:temp[2]
        mov     byte ptr es:[di+2], cl  ; restore last byte

;
;       check for errors
;
PUBLIC chk_err                          ;@1 SDD
chk_err:
        .if     <ZERO ax>                               ;Good Open
          .if     <[subfile_flag] eq 1>                   ; save handle
            mov     ax,sub_handle                           ; subfile
          .else                                             ;  or
            mov     ax,handle                               ; rootfile
          .endif                                            ;
          mov     vmsg_handle,ax                            ;
          jmp     END_FIND_FILE                           ; return
        .elseif <[SYS_ERROR] eq error_mr_un_perform>    ;or really hung
          jmp     END_FIND_FILE                           ; return
        .endif

IFNDEF  FamilyAPI
        .if     <ax EQ error_envvar_not_found>  ;dpath not set error?
          mov     ax, sav_error                   ;report old error
        .endif
ENDIF   ;FamilyAPI

;
; ***** OPEN FAILED, what do we tell the caller
;
        .if     <ax EQ ERROR_OPEN_FAILED> OR           ;FILE DOESN'T EXIST
        .if     <ax EQ ERROR_INVALID_NAME> OR          ;invalid filename
        .if     <ax EQ ERROR_FILE_NOT_FOUND> OR        ;FILE DOESN'T EXIST
        .if     <ax EQ ERROR_PATH_NOT_FOUND> OR        ;BAD PATH
        .if     <ax EQ error_filename_exced_range>     ;BAD FILENAME FORMAT
          MOV     SYS_ERROR,ERROR_FILE_NOT_FOUND          ;SET file not found
        .else
          MOV     SYS_ERROR,ERROR_MR_UN_ACC_MSGF          ;Can't get it
        .endif
        JMP     END_FIND_FILE


;***************************************
;       Matching file found - MSGF_HEADER and CP_DEF_REC for caller
;
GET_SAVED_HANDLE:
        SUB     SI,BX                   ;ADJUST SI TO START OF FILENAME

        MOV     AX,SAVE.HANDLE_S[SI]    ;GET HANDLE FOR CURRENT SAVED.FILENAME
        mov     vmsg_handle,ax          ; save for validate routines
        .if     <[subfile_flag] NE 0>
          mov     sub_handle,ax           ;save as subfile
        .else
          MOV     HANDLE,AX               ;save as root
        .endif

;
;       get component ID here
;
PUBLIC savesub                          ;@1 SDD
savesub:
        push    di                             ;save di
        push    bx                             ;save bx

        xor     bx,bx                          ;clear index
        xor     di,di                          ;clear index
        mov     cx,component_length            ;get component length

        .repeat                                 ;Copy Component ID
          mov     al,ds:save.component_s[si][bx]      ;in save area
          mov     msgf_header.component_id[di],al     ;in read area
          mov     ss:component[di],al
          inc     di
          inc     bx
        .loop

        mov     ax,iseg                 ;GET INSTANCE SEGMENT ADDRESSABILITY
        mov     es,ax                   ;INTO ES
        assume  es:iseg

        MOV     AX,SAVE.MSG_COUNT_S[SI]         ;GET MSG_COUNT
        MOV     MSGF_HEADER.MSG_COUNT,AX
        mov     vmsg_msgcnt,ax

        MOV     AX,SAVE.BASE_MID_S[SI]          ;GET BASE_MID
        MOV     MSGF_HEADER.BASE_MID,AX
        mov     vmsg_baseid,ax

        mov     al,save.indicator_s[si]         ;get indicator byte
        mov     byte ptr msgf_header.indicator,al
        mov     vmsg_indicator,al

        mov     ax,save.version_s[si]           ;get version word
        mov     msgf_header.version,ax
        mov     vmsg_version,ax

        mov     ax,save.cp_data_s[si]           ;get code page pointer
        mov     msgf_header.cp_data,ax

        mov     ax,word ptr save.ext_hdr_s[si]  ;get extended header
        mov     word ptr msgf_header.ext_header,ax
        mov     word ptr vmsg_ext_header,ax
        mov     ax,word ptr save.ext_hdr_s[si+2]
        mov     word ptr msgf_header.ext_header+2,ax
        mov     word ptr vmsg_ext_header+2,ax

        .if     <[subfile_flag] eq 0>
          mov     ax,save.cnty_id_s[si]           ;get country id
          mov     es:cp_def_rec.rec_cnty_id,ax

          mov     ax,save.lang_fid_s[si]          ;get lang family ID
          mov     es:cp_def_rec.rec_lang_id,ax

          mov     ax,save.lang_vid_s[si]          ;get lang version ID
          mov     es:cp_def_rec.rec_lang_verid,ax

          mov     ax,save.cpcount_s[si]           ;get code page count
          mov     es:cp_def_rec.rec_cnt_cp,ax

          xor     bx,bx                   ;Copy
          xor     di,di                   ; Code
          mov     cx,CP_ALL               ;  Page
          .repeat                         ;   Entries
            mov     ax,save.cp_s[si][bx]
            mov     es:cp_def_rec.rec_cp_id[di],ax
            inc     di
            inc     di
            inc     bx
            inc     bx
          .loop
        .endif

        pop     bx                      ;restore it
        pop     di

        MOV     OLD_FILE,1              ;SET OLD FILE FLAG


;*******************************
END_FIND_FILE:
        RET

FIND_FILE       ENDP
;********************************
        SUBTTL  Val_Format Routine
        PAGE
;/********************** START OF SPECIFICATIONS *********************/
;/* SUBROUTINE NAME:  VAL_FORMAT                                     */
;/*                                                                  */
;/* DESCRIPTIVE NAME:  VALIDATE MESSAGE FILE FORMAT                  */
;/*                                                                  */
;/* FUNCTION: VALIDATES THE FORMAT OF THE REQUESTED MESSAGE FILE     */
;/*           AND READS FILE HEADER INFORMATION.                     */
;/*                                                                  */
;/* NOTES:  FILE HANDLE, FILENAME, BASE_MID AND MSG_COUNT ARE SAVED  */
;/*         ONLY IF THE FILE IS VALID.                               */
;/*         THE INFORMATION IS SAVED TO ALLOW THE HANDLE TO BE REUSED*/
;/*         BY THE SAME PROCESS.                                     */
;/*                                                                  */
;/*         Entire function rewritten for J200380 (;BN037;)          */
;/*                                                                  */
;/* RESTRICTIONS: NONE                                               */
;/*                                                                  */
;/* ENTRY POINT:  VAL_FORMAT                                         */
;/*    LINKAGE:   CALL NEAR                                          */
;/*                                                                  */
;/* INPUT:                                                           */
;/*                                                                  */
;/* EXIT-NORMAL:  AX = 0 (VALID FORMAT)                              */
;/*               CRFL = 0                                           */
;/*                                                                  */
;/* EXIT-ERROR:   RETURN CODE IN SYS_ERROR                           */
;/*               CRFL = 1                                           */
;/*                                                                  */
;/*    ERROR_MR_INV_MSGF_FORMAT  Invalid message file format         */
;/*    ERROR_MR_UN_PERFORM       Unable to perform requested function*/
;/*                                 - No more handles                */
;/*                                 - Read or CRC error              */
;/*                                 - Unable to allocate storage     */
;/*                                 - Access denied                  */
;/*                                 - Drive not ready                */
;/*                                                                  */
;/* EFFECTS:  NONE                                                   */
;/*                                                                  */
;/* INTERNAL REFERENCES:                                             */
;/*    ROUTINES:   NONE                                              */
;/*                                                                  */
;/* EXTERNAL REFERENCES:                                             */
;/*    ROUTINES:          DOSREAD                                    */
;/*                       DOSCHGFILEPTR                              */
;/*                       DOSCLOSE                                   */
;/*                       DOSREALLOCSEG                              */
;/*                       DOSSEMREQUEST                              */
;/*                       DOSSEMCLEAR                                */
;/*********************** END OF SPECIFICATIONS **********************/
PUBLIC  VAL_FORMAT
VAL_FORMAT      PROC    NEAR

        push    ds
        push    es
        mov     work_hndl,0             ;init for CLOSE NOT NEEDED

;
;       Read the File Header
;
        PUSH    VMSG_HANDLE             ;Handle
        LEA     AX,MSGF_HEADER          ;BUFFER POINTER
        PUSH    SS                        ;sel
        PUSH    AX                        ;off
        MOV     DX,SIZE HEADER          ;BUFFER LENGTH
        PUSH    DX                        ;
        LEA     CX,RESULT               ;RESULT POINTER
        PUSH    SS                        ;SEL
        PUSH    CX                        ;OFF
        CALL    DOSREAD
        .if     <NONZERO ax> OR         ;I/O error
        .if     <[RESULT] ne dx>        ;or wrong length read
          JMP     VAL_ERR                 ;go tag error
        .endif

;
;       Verify the file Signature
;
PUBLIC verify_signature
verify_signature:
        MOV     AX,iseg                         ;DS:SI --> Signature Value
        MOV     DS,AX                             ;
        LEA     SI,SIGNATURE_MSGF                 ;
        LEA     DI,MSGF_HEADER.SIGNATURE_H      ;ES:DI -> Header Signature
        MOV     AX,SS                             ;
        MOV     ES,AX                             ;
        MOV     CX,SIZE SIGNATURE_H             ;signature size
        REPZ    CMPSB                           ;COMPARE
        jnz     INV_FORMAT                        ;error if no match

        MOV     AX,DS                   ;Restore ISEG addressability
        MOV     ES,AX

;
;       If ROOT file, gotta get & check CodePageData
;
PUBLIC code_page_data
code_page_data:

        .if     <[subfile_flag] eq 0> AND
        .if     <[msgf_header.version] AE 2> AND
        .if     <[msgf_header.cp_data] NE 0>
          ;
          ;       Point to Code Page Data in Message File
          ;
          push    vmsg_handle           ;handle
          xor     dx,dx                 ;code page data offset
          push    dx                      ; HO=0
          push    msgf_header.cp_data     ; LO=CP_DATA
          push    dx                    ;type=0 (from beginning)
          lea     ax,NEW_POINTER        ;new file pointer
          push    ss                      ; segment
          push    ax                      ; offset
          CALL    DOSCHGFILEPTR
          .if     <NONZERO ax>          ;if I/O error
            jmp     val_err               ; exit
          .endif
          ;
          ;       Read Code Page Data from ROOT FILE
          ;
          push    vmsg_handle           ;file handle
          lea     ax,CP_DEF_REC         ;buffer ptr
          push    es                      ;
          push    ax                      ;
          mov     dx,SIZE EXTREC        ;buffer length
          push    dx                      ;
          lea     cx,RESULT             ;result ptr
          push    ss                      ;
          push    cx                      ;
          CALL    DOSREAD
          .if     <NONZERO ax> OR       ;if I/O error
          .if     <[RESULT] NE dx>      ;or wrong length read
            jmp     val_err               ;exit
          .endif
          .if     <[cp_def_rec.rec_cnt_cp] A cp_all>    ;check max count
            jmp     inv_format
          .endif
        .endif


;***********************************************
;       Is there room in ISEG for this file?
;
public check_room_to_save
check_room_to_save:
        .if     <[saved_count] EQ 0>            ;if none currently saved  @F03
          MOV     DI,OFFSET ES:SAVED             ;pt to 1st entry         @F03
          jmp     room_for_1                     ; & use it               @F03
        .elseif <[free_save_struc] NE 0>        ;if one was freed         @F03
          mov     di,free_save_struc             ;pt to free entry        @F03
          jmp     room_for_1                     ; & use it               @F03
        .endif                                                           ;@F03

;
;       INCREASE SIZE OF LOCAL DATA SEGMENT                       ;DCR 704
;
IFNDEF  FamilyAPI
        MOV     SI,SIZE SAVE            ;Size to grow
        PUSH    SI
        DEC     SI
        DEC     SI
        PUSH    DS
        ADD     SI,LAST_SAVE_OFFSET
        PUSH    SI
        CALL    ReallocSeg
        or      ax,ax                           ;ERROR ?
        jz      resiz_ok                        ;no, go save stuff
ELSE
        mov     cx, iSize
        add     cx, SIZE SAVE           ;Size to grow
        push    cx
        mov     ax,iseg
        push    ax
        CALL    DosReallocSeg
        or      ax,ax                           ;ERROR ?
        jnz     save_comp_id_here               ;yes
        mov     si,LAST_SAVE_OFFSET
        add     si,size SAVE
        dec     si
        dec     si
        mov     ax,iSize
        mov     ds:[si],ax
        mov     iSize,cx
        jmp     short resiz_ok
ENDIF;  FamilyAPI

;
;       Even if no room in ISEG, must save COMPONENT ID
;                                and set VMSG_... for current file
;
save_comp_id_here:
        mov     work_hndl,1                     ;set CLOSE IS NEEDED
        xor     si,si                           ;clear index
        mov     cx,component_length             ;get length
        .repeat                                 ;copy the Component ID
          mov     al,msgf_header.component_id[si]
          mov     ss:component[si],al
          inc     si
        .loop

        MOV     AX,MSGF_HEADER.MSG_COUNT        ; message count
        mov     vmsg_msgcnt,ax

        MOV     AX,MSGF_HEADER.BASE_MID         ; base message
        mov     vmsg_baseid,ax

        mov     al,byte ptr msgf_header.indicator       ; table type
        mov     vmsg_indicator,al

        mov     ax,msgf_header.version          ; version
        mov     vmsg_version,ax

        mov     ax,word ptr msgf_header.ext_header      ; extended hdr offset
        mov     word ptr vmsg_ext_header,ax
        mov     ax,word ptr msgf_header.ext_header+2
        mov     word ptr vmsg_ext_header+2,ax

        JMP     EXIT_CRIT_SEC                   ;Skip rest of saving


;***********************************************
;       Re-sizing successful: save Work Area Offsets
;
PUBLIC resiz_ok
resiz_ok:
        MOV     DI,LAST_SAVE_OFFSET
        MOV     DI,DS:[DI].NEXT_SAVE
        MOV     LAST_SAVE_OFFSET,DI

;
;       Save FILENAME, HANDLE and all that neat stuff
;
public ROOM_FOR_1
ROOM_FOR_1:

        push    di              ;save offset to save area

        .if     <[subfile_flag] EQ 0>   ; get filename
          LDS     SI,FILENAME                 ; from stack
        .else
          mov     ax,iseg                     ;
          mov     ds,ax                       ; from ISEG
          lea     si,cp_def_rec.rec_filename  ;
        .endif

        push    ds              ;filename segment
        pop     es                ;
        push    si              ;filename offset
        pop     di                ;

        xor     al,al           ;look for null
        mov     cx,asciiz_len     ;
        repne   scasb             ;
        mov     bx,asciiz_len   ;to get length
        sub     bx,cx             ;

        MOV     AX,iseg
        MOV     ES,AX

        pop     di                      ;restore offset to copy file

        MOV     CX,BX                   ;GET INPUT FILENAME LENGTH
        REP     MOVSB                   ;SAVE INPUT FILENAME

        SUB     DI,BX                   ;POINT TO SAVED.FILENAME
        push    dx                      ; !!! FOLD UP SAVED
        mov     dx,di                   ; !!! FILENAME !!!
        call    fold_up                 ; !!!
        pop     dx                      ; !!!
        .if     <[sys_error] NE 0>      ; any errors ?
          jmp     exit_crit_sec           ; else, report error
        .endif

        MOV     AX,VMSG_HANDLE          ;save file handle
        MOV     ES:SAVE.HANDLE_S[DI],AX

;
;       save component ID here
;
        push    si                      ;save indexes
        push    bx                        ;
        xor     bx,bx                   ;set copy values
        xor     si,si                     ;
        mov     cx,component_length       ;
        .repeat                         ;Copy the component ID
          mov     al,msgf_header.component_id[si] ;
          mov     es:save.component_s[di][bx],al  ;
          mov     ss:component[si],al             ;
          inc     si                              ;
          inc     bx                              ;
        .loop                                     ;
        pop     bx                      ;restore indexes
        pop     si

        MOV     AX,MSGF_HEADER.MSG_COUNT        ; message count
        MOV     ES:SAVE.MSG_COUNT_S[DI],AX
        mov     vmsg_msgcnt,ax

        MOV     AX,MSGF_HEADER.BASE_MID         ; base message
        MOV     ES:SAVE.BASE_MID_S[DI],AX
        mov     vmsg_baseid,ax

        mov     al,byte ptr msgf_header.indicator       ; table type
        mov     es:save.indicator_s[di],al
        mov     vmsg_indicator,al

        mov     ax,msgf_header.version          ; version
        mov     es:save.version_s[di],ax
        mov     vmsg_version,ax

        mov     ax,word ptr msgf_header.ext_header      ; extended hdr offset
        mov     es:word ptr save.ext_hdr_s[di],ax
        mov     word ptr vmsg_ext_header,ax
        mov     ax,word ptr msgf_header.ext_header+2
        mov     es:word ptr save.ext_hdr_s[di+2],ax
        mov     word ptr vmsg_ext_header+2,ax

        mov     ax,msgf_header.cp_data          ; code page ptr
        mov     es:save.cp_data_s[di],ax

;
;       ROOT FILE ONLY: Save Country Code Data (if any)
;
        .if     <NONZERO ax> AND
        .if     <[subfile_flag] EQ 0>
          mov     ax,es:cp_def_rec.rec_cnty_id    ; Country ID
          mov     es:save.cnty_id_s[di],ax
          mov     ax,es:cp_def_rec.rec_lang_id    ; Lang family
          mov     es:save.lang_fid_s[di],ax
          mov     ax,es:cp_def_rec.rec_lang_verid ; Lang Version
          mov     es:save.lang_vid_s[di],ax
          mov     ax,es:cp_def_rec.rec_cnt_cp     ; Code Page Count
          mov     es:save.cpcount_s[di],ax

          push    si                      ; save indexex
          push    bx                        ;
          xor     bx,bx                   ; set up CP copy loop
          xor     si,si                     ;
          mov     cx,CP_ALL                 ;
          .repeat                         ;COPY ALL CP Entries
            mov     ax,es:cp_def_rec.rec_cp_id[si]
            mov     es:save.cp_s[di][bx],ax
            inc     si
            inc     si
            inc     bx
            inc     bx
          .loop
          pop     bx                      ; restore indexes
          pop     si                        ;
        .endif

        .if     <[free_save_struc] EQ 0>        ;not using an old one   @F03
          INC     ES:SAVED_COUNT                 ;bump SAVED count      @F03
        .endif                                   ;                      @F03

EXIT_CRIT_SEC:
        mov     ax,sys_error            ; set up return code
        or      ax,ax                   ; is there an error ?
        jnz     val_err                 ; yes, so report error
        CLC                             ; else, CLEAR CARRY
        JMP     short val_ok            ; RETURN OK


;***********************
;       Invalid file format
;
INV_FORMAT:
        MOV     AX,ERROR_MR_INV_MSGF_FORMAT              ;YES, RETURN ERROR
        JMP     short ERROR_EXIT

;***********************
;
;
VAL_ERR:
        MOV     AX,ERROR_MR_UN_ACC_MSGF

;***********************
;
;
ERROR_EXIT:
        MOV     SYS_ERROR,AX            ;ID the error
        PUSH    VMSG_HANDLE             ;Close the file
        CALL    DOSCLOSE                  ;
        stc                             ;Flag the error


;***********************
;
;
VAL_OK:
        pop     es
        pop     ds
        RET
VAL_FORMAT      ENDP
;********************************
        SUBTTL Val_Mid_Num Routine
        PAGE
;/********************** START OF SPECIFICATIONS *********************/
;/* SUBROUTINE NAME:  VAL_MID_NUM                                    */
;/*                                                                  */
;/* DESCRIPTIVE NAME:  VALIDATE MESSAGE ID NUMBER                    */
;/*                                                                  */
;/* FUNCTION: IF THE MESSAGE NUMBER IS WITHIN THE VALID RANGE AS     */
;/*           DETERMINED BY BASE MESSAGE ID AND MESSAGE COUNT, THEN  */
;/*           THE OFFSET OF THE REQUESTED MESSAGE IS RETURNED.       */
;/*                                                                  */
;/* NOTES:  1RST RESERVED BYTE: 1 = MESSAGE OFFSETS ARE WORDS        */
;/*                             0 = MESSAGE OFFSETS ARE DOUBLE WORDS */
;/*                                                                  */
;/*         Entire function rewritten for J200380 (;BN037;)          */
;/*                                                                  */
;/* RESTRICTIONS: NONE                                               */
;/*                                                                  */
;/* ENTRY POINT:  VAL_MID_NUM                                        */
;/*    LINKAGE:   CALL NEAR                                          */
;/*                                                                  */
;/* INPUT:                                                           */
;/*                                                                  */
;/* EXIT-NORMAL:  AX = 0                                             */
;/*               CRFL = 0                                           */
;/*                                                                  */
;/* EXIT-ERROR:   RETURN CODE IN SYS_ERROR                           */
;/*               CRFL = 1                                           */
;/*                                                                  */
;/*  ERROR_MR_MID_NOT_FOUND     Message ID number not found          */
;/*                                                                  */
;/*                                                                  */
;/* EFFECTS:  NONE                                                   */
;/*                                                                  */
;/* INTERNAL REFERENCES:                                             */
;/*    ROUTINES:   NONE                                              */
;/*                                                                  */
;/* EXTERNAL REFERENCES:                                             */
;/*    ROUTINES:          DOSCHGFILEPTR                              */
;/*                       DOSFREESEG                                 */
;/*                       DOSREAD                                    */
;/*********************** END OF SPECIFICATIONS **********************/
PUBLIC VAL_MID_NUM
VAL_MID_NUM     PROC    NEAR

;
;       Is requested message in this file
;
        MOV     AX,MSGNUMBER            ;requested message
        mov     bx,VMSG_BASEID          ;File - base msg
        mov     cx,VMSG_MSGCNT          ;     - msg count

        MOV     DX,BX                   ;last msg in file
        ADD     DX,CX                     ;
        DEC     DX                        ;

        .if     <ax B bx> OR            ;if BELOW the first
        .if     <ax A dx>               ;or ABOVE the last
          JMP     VAL_MID_NOT_FOUND             ;the message aint here
        .endif

;
;       Find offset to this message's postion in the table of offsets
;               HEADER_LEN + ((MSG_NUMBER - BASE_MID) * len_of_entry)
;
        SUB     AX,BX                   ;MSG_NUMBER - BASE_MID

        .if     <[VMSG_INDICATOR] EQ 1>
          SHL     AX,1                  ;Word offset ( mult by 2 )
        .else
          IFDEF   FamilyAPI
                  shl     ax,1          ;DWord offset ( mult by 2 )
                  shl     ax,1          ;         and ( mult by 2 )
          ELSE
                  SHL     AX,2          ;DWord offset ( mult by 4 )
          ENDIF   ;FamilyAPI
        .endif

        XOR     DX,DX                   ;SET  ZERO
        MOV     CX,SIZE HEADER          ;GET HEADER SIZE
        ADD     AX,CX                   ;AX = @MSG_NUMBER_OFFSET

;
;       Position file pointer at correct entry in the table of offsets
;
        push    VMSG_HANDLE             ;current handle
        PUSH    DX                      ;offset  HI Word = 0
        PUSH    AX                        ;      Lo Word
        PUSH    DX                      ;TYPE = 0 = Start of File + OFFSET
        LEA     AX,NEW_POINTER          ;Addr of NEW POINTER
        PUSH    SS                        ;
        PUSH    AX                        ;
        CALL    DOSCHGFILEPTR

        .if     <NONZERO ax>
          JMP     VAL_MID_IO_ERROR        ;I/O Error
        .endif

;
;       Read two entries from Table of Offsets
;
        push    VMSG_HANDLE             ;current handle
        LEA     AX,MSG_NUM_OFFSET       ;buffer address
        PUSH    SS                        ;
        PUSH    AX                        ;

        .if     <[VMSG_INDICATOR] EQ 1>
          mov     dx,4                  ;len = 4 (2 Word entries)
        .else
          mov     dx,8                  ;len = 8 (2 DWord entries)
        .endif
        push    dx                      ;PUSH LENGTH

        LEA     AX,RESULT               ;PUSH @RESULT
        PUSH    SS                        ;
        PUSH    AX                        ;
        CALL    DOSREAD

        .if     <NONZERO ax> OR
        .if     <[RESULT] NE dx>
          JMP     VAL_MID_IO_ERROR        ;I/O Error
        .endif

        .if     <[VMSG_INDICATOR] EQ 1> ;If word length table
          xchg    ax,MSG_NUM_OFFSETH      ;convert offset
          mov     NXT_MSG_OFFSETL,ax      ;to double word
        .endif

;***********************
;       Check for "Last Message" processing
;
        MOV     AX,MSGNUMBER            ;requested message
        mov     bx,VMSG_BASEID          ;base msg number
        mov     cx,VMSG_MSGCNT          ;msg count
        SUB     AX,BX                   ;last message
        INC     AX                        ; in the file

        .if     <ax NE cx>              ;If NOT last message
          MOV     AX,NXT_MSG_OFFSETL      ;  (only need LO Word ... < 64kb)
          MOV     BX,MSG_NUM_OFFSETL      ;Offset_this
          SUB     AX,BX                   ; - Offset_next
          MOV     MSG_NUMBER_LEN,AX       ;  = message length
          CLC
          JMP     short VAL_MID_EXIT
        .endif

;***********************
;       Process Last Message in file
;
        mov     ax,word ptr VMSG_EXT_HEADER
        mov     bx,word ptr VMSG_EXT_HEADER+2
        or      bx,ax
        .if     <NZ> AND                ;If extended Headers
        .if     <[VMSG_VERSION] EQ 2>   ; & new format
          MOV     BX,MSG_NUM_OFFSETL      ; Offset to Message
          SUB     AX,BX                   ; - Offset to Extended Hdr
          MOV     MSG_NUMBER_LEN,AX         ; = message length { <64kb }
          CLC
          JMP     short VAL_MID_EXIT
        .endif

;
;       Set file pointer to End OF File
;
        push    VMSG_HANDLE             ;current handle
        xor     dx,dx                   ;distance = 0
        PUSH    DX                        ;
        PUSH    DX                        ;
        MOV     AX,2                    ;MOVE TYPE = OEF
        PUSH    AX                        ;
        LEA     AX,NEW_POINTER          ;@ FILESIZE
        PUSH    SS                        ; seg
        PUSH    AX                        ; off
        CALL    DOSCHGFILEPTR

        .if     <NONZERO ax>
          JMP     short VAL_MID_IO_ERROR        ;I/O Error
        .endif

;
;        MSG_NUMBER_LEN = FILESIZE - MSG_NUMBER_OFFSET;
;
        MOV     AX,NEW_POINTERL         ;LO WORD FILESIZE = NEW_POINTERL
        MOV     BX,MSG_NUM_OFFSETL      ;LO WORD  MSG_NUMBER_OFFSET
        SUB     AX,BX                   ;SUBTRACT LO WORD
        MOV     MSG_NUMBER_LEN,AX       ;MSG_NUMBER_LENGTH
        CLC                             ;clear carry flag
        JMP     short VAL_MID_EXIT


;*************** I/O Errors
;
VAL_MID_IO_ERROR:
        STC
        MOV     SYS_ERROR,ERROR_MR_UN_ACC_MSGF
        JMP     short VAL_MID_EXIT


;*************** Message Not Found
;
VAL_MID_NOT_FOUND:
        STC
        MOV     SYS_ERROR,ERROR_MR_MID_NOT_FOUND


;*************** Exit Routine
;
VAL_MID_EXIT:
        RET

VAL_MID_NUM     ENDP
;********************************
        SUBTTL Get_Message Routine
        PAGE
;/********************** START OF SPECIFICATIONS *********************/
;/* SUBROUTINE NAME:  GET_MESSAGE                                    */
;/*                                                                  */
;/* DESCRIPTIVE NAME:  GET REQUESTED MESSAGE                         */
;/*                                                                  */
;/* FUNCTION: MOVE FILE POINTER TO OFFSET OF REQUESTED MESSAGE, AND  */
;/*           READ MESSAGE TEXT INTO LOCAL BUFFER.                   */
;/*                                                                  */
;/* NOTES:  Entire function rewritten for J200380 (;BN037;)          */
;/*                                                                  */
;/* RESTRICTIONS: NONE                                               */
;/*                                                                  */
;/* ENTRY POINT:  GET_MESSAGE                                        */
;/*    LINKAGE:   CALL NEAR                                          */
;/*                                                                  */
;/* INPUT:                                                           */
;/*                                                                  */
;/* EXIT-NORMAL:  AX = 0                                             */
;/*               CRFL = 0                                           */
;/*                                                                  */
;/* EXIT-ERROR:   RETURN CODE IN SYS_ERROR                           */
;/*               CRFL = 1                                           */
;/*                                                                  */
;/*    ERROR_MR_UN_PERFORM       Unable to perform requested function*/
;/*                                 - No more handles                */
;/*                                 - Read or CRC error              */
;/*                                 - Unable to allocate storage     */
;/*                                 - Access denied                  */
;/*                                 - Drive not ready                */
;/*                                                                  */
;/* EFFECTS:  NONE                                                   */
;/*                                                                  */
;/* INTERNAL REFERENCES:                                             */
;/*    ROUTINES:   NONE                                              */
;/*                                                                  */
;/* EXTERNAL REFERENCES:                                             */
;/*    ROUTINES:          DOSREAD                                    */
;/*                       DOSCHGFILEPTR                              */
;/*                       DOSALLOCSEG                                */
;/*                       DOSFREESEG                                 */
;/*********************** END OF SPECIFICATIONS **********************/
PUBLIC GET_MESSAGE
GET_MESSAGE     PROC    NEAR

        CLC
        xor     dx,dx                   ;gonna need some zeros

;
;       Get a local buffer
;
        PUSH    MSG_NUMBER_LEN          ;BUFFER LENGTH
        LEA     AX,MSG_SEL              ;@SELECTOR
        PUSH    SS                        ;
        PUSH    AX                        ;
        push    dx                      ;NOT SHARED
        CALL    DOSALLOCSEG

        .if     <NONZERO ax>                    ;if alloc failed
          MOV     SYS_ERROR,ERROR_MR_UN_PERFORM   ;ERROR CODE
          STC                                     ;& flag
          JMP     GET_END                         ;
        .endif

;
;       Set file pointer to start of message
;
        push    VMSG_HANDLE             ;current handle
        PUSH    MSG_NUM_OFFSETH         ;Offset (HO Word)
        PUSH    MSG_NUM_OFFSETL           ;     (LO Word)
        push    dx                      ;TYPE 0 = FROM START OF FILE + DISTANCE
        LEA     AX,NEW_POINTER          ;GET NEW POINTER OFFSET
        PUSH    SS                      ;PUSH NEW POINTER SELECTOR
        PUSH    AX                      ;PUSH NEW POINTER OFFSET
        CALL    DOSCHGFILEPTR

        .if     <NONZERO ax>
          JMP     GET_MSG_ERR             ;JUMP IF ERROR
        .endif

;
;       READ MESSAGE TEXT
;
        push    VMSG_HANDLE             ;handle
        PUSH    MSG_SEL                 ;addr of buffer
        push    dx                        ; (offset=0)
        mov     bx,MSG_NUMBER_LEN       ;buffer length
        push    bx                        ;
        LEA     CX,RESULT               ;addr for read length
        PUSH    SS                        ;
        PUSH    CX                        ;
        CALL    DOSREAD

        .if     <ZERO ax> AND           ;read OK
        .if     <[result] EQ bx>        ;& correct length
          JMP     GET_END                 ;all done
        .endif


;***********************
;       Read Error Processing
;
GET_MSG_ERR:
        PUSH    MSG_SEL                         ;free buffer
        CALL    DOSFREESEG                        ;
        MOV     SYS_ERROR,ERROR_MR_UN_ACC_MSGF  ;flag the error
        STC                                       ;


;***********************
;       Function exit
;
PUBLIC GET_END
GET_END:
        RET


GET_MESSAGE     ENDP
;********************************
        SUBTTL Fold_Up Routine
        PAGE
;/********************** START OF SPECIFICATIONS *********************/
;/* SUBROUTINE NAME:  FOLD_UP                                        */
;/*                                                                  */
;/* DESCRIPTIVE NAME:  FOLD FILENAME TO UPPERCASE                    */
;/*                                                                  */
;/* FUNCTION: FOLDS FILENAME TO UPPERCASE. SKIPS ALL DOUBLE BYTE     */
;/*           CHARACTERS. ONCE ASCIIZ STRING HAS BEEN PROCESSED,     */
;/*           DOSCASEMAP IS CALLED TO FOLD CHARACTERS GREATER THAN   */
;/*           7FH.                                                   */
;/*                                                                  */
;/* NOTES:  NONE                                                     */
;/*                                                                  */
;/* RESTRICTIONS: NONE                                               */
;/*                                                                  */
;/* ENTRY POINT:  FOLD_UP                                            */
;/*    LINKAGE:   CALL NEAR                                          */
;/*                                                                  */
;/* INPUT:                                                           */
;/*|2A      ES:DI = END OF INPUT FILENAME                            */
;/*|2A      DX = START OF FILENAME                                   */
;/*|2A      BX = STRING LENGTH                                       */
;/*                                                                  */
;/* EXIT-NORMAL:                                                     */
;/*               ES:DI = FOLDED FILENAME                            */
;/*                                                                  */
;/* EXIT-ERROR:                                                      */
;/*               SYS_ERROR = ERROR CODE                             */
;/*               ERRORR_MR_UN_PERFORM                               */
;/*                                                                  */
;/* EFFECTS:  NONE                                                   */
;/*                                                                  */
;/* INTERNAL REFERENCES:                                             */
;/*    ROUTINES: NONE                                                */
;/*                                                                  */
;/* EXTERNAL REFERENCES:                                             */
;/* |  ROUTINES:                                                     */
;/* |2A                  CHK_LEAD_BYTE                               */
;/* |2A                  DOSCASEMAP                                  */
;/*********************** END OF SPECIFICATIONS **********************/
FOLD_UP         PROC    NEAR
;
;
; GET INPUT FILENAME  POINTER;
; WHILE NOT EO STRING DO;
;    GET BYTE;
;    IF  DBCS = TRUE AND IS_LEAD_BYTE = TRUE THEN
;        ADVANCE 2 CHARACTERS;
;    ELSE
;        IF BYTE >= 'a' AND BYTE <= 'z' THEN
;            BYTE = BYTE AND 0DFH;
;        ADVANCE 1 CHARACTER;
; END;
; CALL DOSCASEMAP - FOLD CHARS > 7FH;
; END FOLD_UP;
;
        PUSH    DI                      ;SAVE FILENAME OFFSET
        PUSH    BX                      ;SAVE COUNTER
        MOV     SYS_ERROR,0             ;INITIALIZE ERROR
        mov     casemap_char,0          ;set case mapping flag to 0

; GET INPUT FILENAME  POINTER;
;       ES:DI --> END OF FILENAME
;
        MOV     DI,DX                   ;RESET POINTER TO START OF FILENAME
;
; WHILE NOT EO STRING DO;
;
FOLD_LOOP:
;
        or      bx,bx
        JZ      FOLD_DONE              ;IF YES, DONE
;
;    GET BYTE;
;
        MOV     AL,BYTE PTR ES:[DI]
;
;    IF  DBCS = TRUE AND IS_LEAD_BYTE = TRUE THEN
;
        CMP     IS_DBCS,1                       ;IS DBCS?
        JNZ     SINGLE_BYTE_FOLD                ;NO, SO JMP TO SINGLE BYTE ROUTINE
;
;         CALL CHK_LEAD_BYTE - CHECK FOR LEAD BYTE;
;
        CALL    CHK_LEAD_BYTE           ;CHECK FOR LEAD BYTE CHAR
        JNC     SINGLE_BYTE_FOLD        ;JUMP TO SINGLE BYTE ROUTINE IF NOT LEAD BYTE
;
        cmp     bx,2                    ;check for remaining bytes to be processed >= 2
        jb      single_byte_fold        ;if less, jump

;        ADVANCE 2 CHARACTERS;
;
        ADD     DI,2                    ;else bump pointer
        SUB     BX,2                    ;DECREMENT COUNTER
        JMP     FOLD_LOOP
;
;    ELSE
;        IF BYTE >= 'a' AND BYTE <= 'z' THEN
;
SINGLE_BYTE_FOLD:
;
        CMP     AL,'a'
        JB      SKIP_FOLD
        CMP     AL,'z'
        JA      SKIP_FOLD
;
;            BYTE = BYTE AND 0DFH;
;
        AND     AL,0DFH
        STOSB                           ;STORE AND ADVANCE 1 CHARACTER
        DEC     BX                      ;DECREMENT COUNTER
        JMP     FOLD_LOOP
;
SKIP_FOLD:
;
        cmp     al,127                  ;check for char > 127 ASCII
        jbe     char_advance            ;if char <= 127 ASCII, then skip
        mov     casemap_char,1          ;else string needs to be case mapped
;
;        ADVANCE 1 CHARACTER;
;
char_advance:
        INC     DI
        DEC     BX                      ;DECREMENT COUNTER
        JMP     FOLD_LOOP
; END;
;
FOLD_DONE:
;
; CALL DOSCASEMAP - FOLD CHARS > 7FH;
;
        POP     BX                      ;RESTORE LENGTH

        .if     <[casemap_char] EQ 1>   ;If need to FOLD Upper chars
          PUSH    BX                      ;LENGTH
          LEA     AX,COUNTRY_CODE         ;ADDR OF COUNTRY CODE
          PUSH    ISEG                    ; ;BN029
          PUSH    AX                      ; ;
          PUSH    ES                      ;ADDR OF STRING
          PUSH    DX                      ; ;
          CALL    DOSCASEMAP              ;
        .endif                            ;

        POP     DI                      ;RESTORE FILENAME OFFSET
        RET
FOLD_UP         ENDP
;********************************
        SUBTTL Filename_Strip Routine
        PAGE
;/********************** START OF SPECIFICATIONS *********************/
;/* SUBROUTINE NAME:  FILENAME_STRIP                                 */
;/*                                                                  */
;/* DESCRIPTIVE NAME:  STRIP FILENAME OUT OF INPUT STRING            */
;/*                                                                  */
;/* FUNCTION: SETS POINTER TO FILENAME IN STRING PASSED BY CALLER.   */
;/*                                                                  */
;/* NOTES:  NONE                                                     */
;/*                                                                  */
;/* RESTRICTIONS: NONE                                               */
;/*                                                                  */
;/* ENTRY POINT:  FILENAME_STRIP                                     */
;/*    LINKAGE:   CALL NEAR                                          */
;/*                                                                  */
;/* INPUT:                                                           */
;/*|2A      ES:DI = end   OF INPUT STRING                            */
;/*|2A      DX = START OF FILENAME                                   */
;/*|2A      BX = STRING LENGTH                                       */
;/*                                                                  */
;/* EXIT-NORMAL:                                                     */
;/*               ES:DI = FILENAME (NAME.EXT ONLY)                   */
;/*                                                                  */
;/* EXIT-ERROR:                                                      */
;/*               NONE                                               */
;/*                                                                  */
;/* EFFECTS:  NONE                                                   */
;/*                                                                  */
;/* INTERNAL REFERENCES:                                             */
;/*    ROUTINES: NONE                                                */
;/*                                                                  */
;/* EXTERNAL REFERENCES:                                             */
;/* |  ROUTINES:                                                     */
;/* |2A                  CHK_LEAD_BYTE                               */
;/*********************** END OF SPECIFICATIONS **********************/
PUBLIC FILENAME_STRIP                   ;DCR 361
FILENAME_STRIP  PROC    NEAR
;
; INITIALIZE COLUMN COUNT TO ZERO;
; INITIALIZE IS_BC TO ZERO;
; DO WHILE NOT END OF STRING;
;   GET BYTE;
;   IF DBCS = TRUE AND IS LEAD BYTE = TRUE THEN
;      ADVANCE 2 BYTES;
;      COLUMN COUNT = COLUMN COUNT + 2;
;      STRING LENGTH = STRING LENGTH - 2;
;   ELSE
;      IF BYTE = '\' OR BYTE = ':' THEN
;         IS_BC = COLUMN COUNT;
;      ADVANCE 1 BYTE;
;      COLUMN COUNT = COLUMN COUNT + 1;
;      STRING LENGTH = STRING LENGTH - 1;
; END;
;  POINTER = POINTER - ( COLUMN COUNT - IS_BC ) ;
;END FILENAME_STRIP;
;
        PUSH    BX                                ;SAVE STRING LENGTH
        PUSH    CX                              ;SAVE REGISTER
        PUSH    DX                              ;SAVE REGISTER
        mov     di,dx                           ;point to start of filename
;
; INITIALIZE COLUMN COUNT TO ZERO;
;
        XOR     CX,CX
;
; INITIALIZE IS_BC TO ZERO;
;
        XOR     DX,DX
;
; DO WHILE NOT END OF STRING;
;
FILENAME_LOOP:

        or      bx,bx
        JNZ     DO_STRIP
        JMP     FILENAME_OUT
;
DO_STRIP:
;
;   GET BYTE;
;
        MOV     AL,BYTE PTR ES:[DI]
;
;    IF  DBCS = TRUE AND IS_LEAD_BYTE = TRUE THEN
;
        CMP     IS_DBCS,1                       ;IS DBCS?
        JNZ     BACKSLASH_CHK                   ;NO, SO JMP TO SINGLE BYTE ROUTINE
;
;         CALL CHK_LEAD_BYTE - CHECK FOR LEAD BYTE;
;
        CALL    CHK_LEAD_BYTE            ;CHECK FOR LEAD BYTE CHAR
        JNC     BACKSLASH_CHK           ;JUMP TO SINGLE BYTE ROUTINE IF NOT LEAD BYTE

        cmp     bx,2                    ;check for remaining bytes to be processed >= 2
        jb      backslash_chk           ;if less, jump

;
;      ADVANCE 2 CHARACTERS;
;      COLUMN COUNT = COLUMN COUNT + 2;
;      STRING LENGTH = STRING LENGTH - 2;
;
        ADD     DI,2                    ;BUMP POINTER
        ADD     CX,2                    ;INCREMENT COLUMN COUNT
        SUB     BX,2                    ;DECREMENT COUNTER
        JMP     FILENAME_LOOP
;
BACKSLASH_CHK:
;
;    ELSE
;      IF BYTE = '\' OR BYTE = ':' THEN
;         IS_BC = COLUMN COUNT;
;
        CMP     AL,'\'
        JNZ     COLON_CHK
        MOV     DX,CX                   ;IS_BC = COLUMN COUNT
        inc     DX                      ;bump to next char to adjust pointer
        JMP     NOT_B_OR_C
COLON_CHK:
        CMP     AL,':'
        JNZ     NOT_B_OR_C
        MOV     DX,CX                    ;IS_BC = COLUMN COUNT
        inc     DX                      ;bump to next char to adjust pointer
NOT_B_OR_C:
;
;      ADVANCE 1 BYTE;
;      COLUMN COUNT = COLUMN COUNT + 1;
;      STRING LENGTH = STRING LENGTH - 1;
;
        INC     DI
        INC     CX
        DEC     BX
        JMP     FILENAME_LOOP
;
;END;
;
PUBLIC FILENAME_OUT                             ;@1 SDD
FILENAME_OUT:
;
;  POINTER = POINTER - ( COLUMN COUNT - IS_BC );
;
        SUB     CX,DX
        SUB     DI,CX                           ;ES:DI --> FILENAME ONLY
;
;END FILENAME_STRIP;
;
        POP     DX                              ;RESTORE REGISTER
        POP     CX                              ;RESTORE REGISTER
        POP     BX                              ;RESTORE STRING LENGTH
;
        RET
FILENAME_STRIP  ENDP
;********************************
        SUBTTL GetBootRoot Routine
        PAGE
IFNDEF  FamilyAPI
;/********************** START OF SPECIFICATIONS *********************/
;/* SUBROUTINE NAME:  GETBOOTROOT                                    */
;/*                                                                  */
;/* DESCRIPTIVE NAME:  GET BOOT DISK DRIVE LETTER FROM INFOSEG       */
;/*                                                                  */
;/* FUNCTION: RETURNS BOOT DISK DRIVE LETTER FROM INFOSEG BY CALLING */
;/*         DOSGETINFOSEG, AND CONVERTING RETURN TO LETTER           */
;/*         (1=A, 2=B,...)                                           */
;/*                                                                  */
;/* NOTES:  NONE                                                     */
;/*                                                                  */
;/* RESTRICTIONS: NONE                                               */
;/*                                                                  */
;/* ENTRY POINT:  GETBOOTROOT                                        */
;/*    LINKAGE:   CALL NEAR                                          */
;/*                                                                  */
;/* INPUT:     DS --> ISEG                                           */
;/*                                                                  */
;/* EXIT-NORMAL:                                                     */
;/*             CX = DRIVE SPECIFIER                                 */
;/*                                                                  */
;/* EXIT-ERROR:                                                      */
;/*             CX = 00                                              */
;/*                                                                  */
;/* EFFECTS:  NONE                                                   */
;/*                                                                  */
;/* INTERNAL REFERENCES:                                             */
;/*    ROUTINES: NONE                                                */
;/*                                                                  */
;/* EXTERNAL REFERENCES:                                             */
;/* |  ROUTINES:                                                     */
;/* |2A                 DOSGETENV                                    */
;/*********************** END OF SPECIFICATIONS **********************/
GETBOOTROOT   PROC    NEAR
;
; CALL DOSGETINFOSEG - GET INFOSEG;
; SET POINTER TO BOOT_DEVICE OFFSET IN GLOBAL SEGMENT;
; GET BOOT DEVICE NUMBER;
; CONVERT BOOT DEVICE TO DRIVER LETTER;
; END;
;
      PUSH    DS                      ;SAVE REGISTERS
      PUSH    SI
      XOR     CX,CX                   ;return drive letter not found

; @WWM now done in MSGINIT
; CALL DOSGETINFOSEG - GET INFOSEG;
;
;     PUSH    SS
;     LEA     AX,GLOBALSEG
;     PUSH    AX                      ;PUSH ADDRESS OF GLOBAL SEGMENT
;     PUSH    SS
;     LEA     AX,LOCALSEG
;     PUSH    AX                        ;PUSH ADDRESS OF LOCAL SEGMENT
;     CALL    DOSGETINFOSEG
;
;     MOV     AX,GLOBALSEG

      mov     ax,initseg              ;Get addressability to initseg
      mov     ds,ax

      assume  ds:initseg

      mov     ax,GlobalSeg
      MOV     DS,AX                              ;DS -> START OF GLOBAL SEGMENT
;
; SET POINTER TO BOOT_DEVICE OFFSET IN GLOBAL SEGMENT;

      MOV     SI,SIS_BOOTDRV                     ;DS:SI -> BOOT DEVICE NUMBER

; GET BOOT DEVICE NUMBER;

      MOV     CL,BYTE PTR [SI]

; CONVERT BOOT DEVICE TO ASCII DRIVER LETTER;

      ADD     CX,3A40H                ;CX = DRIVE LETTER + ':'
;
;
; END;
;
      POP     SI
      POP     DS                              ;RESTORE REGISTERS
              RET
GETBOOTROOT   ENDP
ELSE
PAGE
;/********************** START OF SPECIFICATIONS *********************/
;/* SUBROUTINE NAME:  GETBOOTROOT                                    */
;/*                                                                  */
;/* DESCRIPTIVE NAME:  GET BOOT DISK DRIVE LETTER FROM ENVIRONMENT   */
;/*                                                                  */
;/* FUNCTION: RETURNS BOOT DISK DRIVE LETTER FROM THE ENVIRONMENT    */
;/*           VECTOR SET AT INITIALIZATION.                          */
;/*           INITIALLY, USE 'COMSPEC='                              */
;/*                                                                  */
;/* NOTES:  NONE                                                     */
;/*                                                                  */
;/* RESTRICTIONS: NONE                                               */
;/*                                                                  */
;/* ENTRY POINT:  GETBOOTROOT                                        */
;/*    LINKAGE:   CALL NEAR                                          */
;/*                                                                  */
;/* INPUT:     DS --> ISEG                                           */
;/*                                                                  */
;/* EXIT-NORMAL:                                                     */
;/*               CX = DRIVE SPECIFIER                               */
;/*                                                                  */
;/* EXIT-ERROR:                                                      */
;/*               CX = 00                                            */
;/*                                                                  */
;/* EFFECTS:  NONE                                                   */
;/*                                                                  */
;/* INTERNAL REFERENCES:                                             */
;/*    ROUTINES: NONE                                                */
;/*                                                                  */
;/* EXTERNAL REFERENCES:                                             */
;/* |  ROUTINES:                                                     */
;/* |2A                  DOSGETENV                                   */
;/*********************** END OF SPECIFICATIONS **********************/
GETBOOTROOT     PROC    NEAR
;
; CALL DOSGETENV - GET ENVIRONMENT;
; DO WHILE NOT END OF ENVIRONMENT SPACE;
;    IF STRING <> 'COMSPEC' THEN
;       MOVE POINTER TO NEXT ENVIRONMENT STRING;
;    ELSE
;       IF NEXT NON BLANK = '=' THEN
;          GET NEXT 2 NON BLANK CHARACTERS;
; END;
;
        PUSH    ES                      ;SAVE FILENAME POINTER
        PUSH    DI
        mov     cx,0                    ;return drive letter not found
;
; CALL DOSGETENV - GET ENVIRONMENT;
;
        PUSH    SS
        LEA     AX,ENVSEGMENT
        PUSH    AX                      ;PUSH ADDRESS OF ENVIRONMENT STRING
        PUSH    SS
        LEA     AX,CMDOFFSET
        PUSH    AX                      ;PUSH ADDRESS OF CMD LINE OFFSET
        CALL    DOSGETENV
        or      ax,ax
        JNZ     BOOT_OUT                ;EXIT ON ERROR
;
        MOV     AX,ENVSEGMENT
        MOV     ES,AX
        XOR     DI,DI                   ;ES:DI -> START OF ENVIRONMENT SPACE
;
; DO WHILE NOT END OF ENVIRONMENT SPACE;
;
BOOT_LOOP:
;
        mov     cx,0                            ;return drive letter not found
        CMP     BYTE PTR ES:[DI],0              ;END OF ENVIRONMENT SPACE ?
        JZ      BOOT_OUT                        ;YES, THEN JUMP
;
;    IF STRING <> 'COMSPEC' THEN
;
        LEA     SI,ENVSTRING                    ;DS:SI -> ENVIRONMENT MATCH STRING
        MOV     CX,ENVSTRING_SIZE               ;GET LENGTH TO COMPARE
        REPE    CMPSB                           ;COMPARE ENVIRONMENT MATCH STRING
        JNE     ENV_DONT_MATCH                  ;COMPARE NEXT ENV STRING
        JMP     ENV_MATCH                       ;MATCH !
;
ENV_DONT_MATCH:
;
;       MOVE POINTER TO NEXT ENVIRONMENT STRING;
;
        MOV     AL,0                            ;CHECK FOR EOSTRING
        MOV     CX,ASCIIZ_LEN                   ;CX = MAX ASCIIZ LEN
        REPNE   SCASB                           ;SCAN TIL EOSTRING
        JMP     BOOT_LOOP                       ;DO AGAIN

ENV_MATCH:
;
;      ELSE
;       IF NEXT NON BLANK = '=' THEN
;
        MOV     AL,'='                          ;CHECK FOR '='
        MOV     CX,ASCIIZ_LEN                   ;CX = MAX ASCIIZ LEN
        SUB     CX,ENVSTRING_SIZE               ; - MATCH ENV STRING
        REPNE   SCASB                           ;SCAN TIL '='
;
;          GET NEXT 2 NON BLANK CHARACTERS;
;
        MOV     AL,' '                          ;CHECK FOR blanks
        REPE    SCASB                           ;SCAN TIL FIRST NON BLANK
        CMP     BYTE PTR ES:[DI],':'            ;DRIVE LETTER SPECIFIED?
        JZ      GET_DRIVE                       ;IF YES, THE GET IT
        MOV     CX,0                            ;ELSE, RETURN ZERO
        JMP     BOOT_OUT
GET_DRIVE:
        dec     di                              ;adjust pointer
        MOV     CX,WORD PTR ES:[DI]             ;GET FIRST 2 CHARS OF PATH
;
; END;
;
;
BOOT_OUT:
;
        POP     DI
        POP     ES                      ;RESTORE FILENAME POINTER
                RET
GETBOOTROOT     ENDP
ENDIF ;FamilyApi
;********************************
        SUBTTL CopyRetMsg       Routine
        PAGE
;/********************** START OF SPECIFICATIONS *********************/
;/* SUBROUTINE NAME:  COPYRETMSG                                     */
;/*                                                                  */
;/* DESCRIPTIVE NAME:  COPY RETURN MESSAGE INTO CALLERS BUFFER       */
;/*                                                                  */
;/* FUNCTION: CALLS DOSINSMESSAGE TO COPY AN ERROR MESSAGE WHICH     */
;/*               WAS LINKED IN WITH THE MESSAGE RETRIEVER           */
;/*                                                                  */
;/* NOTES:  NONE                                                     */
;/*                                                                  */
;/* RESTRICTIONS: NONE                                               */
;/*                                                                  */
;/* ENTRY POINT:  COPYRETMSG                                         */
;/*    LINKAGE:   CALL NEAR                                          */
;/*                                                                  */
;/* INPUT:     NONE                                                  */
;/*                                                                  */
;/* EXIT-NORMAL:                                                     */
;/*               NONE                                               */
;/*                                                                  */
;/* EXIT-ERROR:                                                      */
;/*               NONE                                               */
;/*                                                                  */
;/* EFFECTS:  NONE                                                   */
;/*                                                                  */
;/* INTERNAL REFERENCES:                                             */
;/*    ROUTINES: NONE                                                */
;/*                                                                  */
;/* EXTERNAL REFERENCES:                                             */
;/* |  ROUTINES:                                                     */
;/* |2A                  DOSINSMESSAGE                               */
;/*********************** END OF SPECIFICATIONS **********************/
COPYRETMSG      PROC    NEAR
;
;       if error = error_mr_inv_ivcount OR error = error_mr_un_perform
;
        mov     ivcount,0                       ; no test substitution
        cmp     sav_error,error_mr_inv_ivcount
        jz      do_get_err_msg                  ; go get error message text
        cmp     sav_error,error_mr_un_perform
        jz      do_get_err_msg                  ; go get error message text
;
;
;    SET UP IVTABLE, IVCOUNT AND POINTERS TO FILENAME
;
        MOV     IVCOUNT,1                       ;1 TEXT SUBSTITUTION
;
;    IF ERROR = FILE NOT FOUND OR ERROR = UNABLE TO ACCESS MESSAGE FILE
;    or error = cant format msg THEN
;
        CMP     SAV_ERROR,ERROR_FILE_NOT_FOUND
        JZ      SETUP_FILENAME
        CMP     SAV_ERROR,ERROR_MR_UN_ACC_MSGF
        JZ      SETUP_FILENAME
        CMP     SAV_ERROR,ERROR_MR_INV_MSGF_FORMAT
        JZ      SETUP_FILENAME
        cmp     sav_error,error_mr_mid_not_found
        jz      setup_filename
        JMP     DO_UN_GET_ERR_MSG               ;process unable to get error message

SETUP_FILENAME:
        mov     ax,iseg
        mov     ds,ax                           ; use storage area for filename
        lea     si,file_name                    ;DS:SI -> filename

;SETUP_ERR_MSG:
        MOV     AX,DS
        MOV     ERR2_IVTABLEH,AX                ;STORE FILENAME SELECTOR
        MOV     ERR2_IVTABLEL,SI                ;STORE FILENAME OFFSET
;
;       if error = error_mr_mid_not_found then
;
        cmp     sav_error, error_mr_mid_not_found ; go get 1rst entry into
        jz      do_un_get_err_msg                 ; ivtable = message id

        CMP     sav_error,error_file_not_found    ; test for 2 for 318 ; B040 ;
        jz      do_un_get_err_msg                 ; ivtable = message id like 317 ; B040 ;

        MOV     IVTABLEH,SS                     ;MOVE POINTER TO ERR2_IVTABLE INTO
        LEA     AX,ERR2_IVTABLEL                ;IVTABLE FOR ERROR
        MOV     IVTABLEL,AX                     ;PROCESSING

        JMP     DO_GET_ERR_MSG

do_un_get_err_msg:
        lea     si,mid_string
        mov     ax,msgnumber                    ;get message number to convert
        call    decdump                         ;convert message number and
                                                ;store in mid_string
        mov     err1_ivtableh,es                ;store mid_string selector
        mov     err1_ivtablel,si                ;store mid_string offset


        mov     ivtableh,ss                     ;move pointer to err1_ivtable into
        lea     ax,err1_ivtablel                ;ivtable for error
        mov     ivtablel,ax                     ;processing

        mov     ivcount, 2                      ; 1) message ID
;                                               ; 2) filename
DO_GET_ERR_MSG:
;
IFDEF   FamilyAPI                               ; DCR900
;**************************************************************************
; The following code is for FamilyAPI only.     ; DCR900
;**************************************************************************
;

        mov     ax,msgseg                       ; DS -> msgseg
        mov     ds,ax
        assume  ds:msgseg

        CMP     SAV_ERROR,ERROR_FILE_NOT_FOUND
        JNZ     not_file_not_found

        LEA     SI,TXT_MSG_MR_NOT_FOUND         ; DS:SI -> LENGTH WORD
        JMP     return_error_msg

not_file_not_found:

        CMP     SAV_ERROR,ERROR_MR_UN_ACC_MSGF
        JNZ     not_un_acc_msgf

        LEA     SI,TXT_MSG_MR_READ_ERROR        ; DS:SI -> LENGTH WORD
        JMP     return_error_msg

not_un_acc_msgf:

        CMP     SAV_ERROR,ERROR_MR_INV_MSGF_FORMAT
        JNZ     not_inv_format

        LEA     SI,TXT_MSG_MR_READ_ERROR        ; DS:SI -> LENGTH WORD
        JMP     return_error_msg

not_inv_format:

        CMP     SAV_ERROR,ERROR_MR_INV_IVCOUNT
        JNZ     not_inv_ivcount

        LEA     SI,TXT_MSG_MR_IVCOUNT_ERROR     ; DS:SI -> LENGTH WORD
        JMP     return_error_msg

not_inv_ivcount:

        CMP     SAV_ERROR,ERROR_MR_UN_PERFORM
        JNZ     not_un_perform

        LEA     SI,TXT_MSG_MR_UN_PERFORM        ; DS:SI -> LENGTH WORD
        JMP     return_error_msg

not_un_perform:

        LEA     SI,TXT_MSG_MR_CANT_FORMAT       ; DS:SI -> LENGTH WORD

return_error_msg:

        mov     bx,word ptr [si]                ; get message length
        add     si,2                            ; ds:si -> message text
;
ELSE                                            ; DCR900
;**************************************************************************
; The following code is for NON-FamilyAPI only. ; DCR900
;**************************************************************************
;
;  reset file not found error to un_acc_msgf
;
        CMP     SAV_ERROR,ERROR_FILE_NOT_FOUND  ; DCR900
        JNZ     not_file_not_found              ; DCR900
        mov     sav_error,error_mr_un_acc_msgf  ; DCR900
not_file_not_found:                             ; DCR900

;
;  setup parameters for RAMFIND function call
;
;       mov     cx,0                            ;BD032;
suregot:                                        ; DCR900
        push    ds                              ; DCR900
        lea     ax,err_component                ; DCR900
        push    ax                              ; DCR900

        lea     di,err_filename                 ; DCR900
        push    ds                              ; DCR900
        push    di                              ; DCR900

        mov     ax,seg DOSGETMESSAGE            ; DCR900
        push    ax                              ; DCR900
        mov     ax,offset DOSGETMESSAGE         ; DCR900
        sub     ax,BOUNDHDRSIZE                 ; DCR900
        push    ax                              ; DCR900

        push    sav_error                       ; DCR900

;       or      cx,cx                           ;BD032;
;       jz      usecurcp                        ;BD032;
;       mov     CPLIST,0                        ;BD032;
;usecurcp:                                      ;BD032;

        push    ss                              ; DCR900
        lea     ax,CPLIST                       ; DCR900
        push    ax                              ; DCR900

        call    RAMFIND                         ; DCR900
        jnc     gotdata                         ; DCR900

        mov     ax, WORD PTR CPLIST             ;BN032; Verify codepage
        or      ax, ax                          ;BC032;  *
        jz      goback                          ;BC032;  * OOPS - no MSR messages

;
;  Guarantee that RAMFIND will get default MSG (codepage=0)
;
        xor     ax, ax                          ;BN032; Universal codepage = 0
        mov     WORD PTR CPLIST, ax             ;BC032;  *
        mov     ax, iseg                        ;BN032; Restore ISEG ptr
        mov     ds, ax                          ;BN032;  *
        jmp     suregot                         ;DCR900 Try again


gotdata:                                        ; DCR900
;***********************************
; Make sure error & warning class.
;***********************************
        cmp     byte ptr [si-1],ERROR_CLASS     ; B714798
        jz      chk_range                       ; B714798
        cmp     byte ptr [si-1],WARNING_CLASS   ; B714798
        jz      chk_range                       ; B714798
        jmp     short no_checking               ; B714798
chk_range:                                      ; B714798
        cmp     sav_error,error_mr_mid_not_found; B714798
        jl      no_checking                     ; B714798
        cmp     sav_error,error_mr_inv_ivcount  ; B714798
        jg      no_checking                     ; B714798
        mov     ax,sav_error                    ; B714798
;**************************************************************************
; Skip checking sys_error because insert fail will be verified at next level
;**************************************************************************
        push    ds                              ; B714798
        call    copymsghd                       ; B714798
;**************************************************************************
; Set it up for text string replacement.
;**************************************************************************
        mov     ax,iseg                         ; B714798
        mov     ds,ax                           ; B714798
        push    si                              ; B714798
        lea     si,file_name                    ; B714798
        mov     err2_ivtableh,ax                ; B714798
        mov     err2_ivtablel,si                ; B714798
        cmp     sav_error,error_mr_mid_not_found; B714798
        jz      error_mid                       ; B714798 ; goto 317 processing ; B040 ;
        cmp     sav_error,error_mr_un_acc_msgf  ; test for 318 like 317 ; B040 ;
        jnz     no_error_mid                    ; goto not process like 317 ; B040 ;
error_mid:
        lea     si,ss:mid_string                ; B714798
        mov     ax,msgnumber                    ; B714798
        call    decdump                         ; B714798
        mov     err1_ivtableh,ss                ; B714798
        mov     err1_ivtablel,si                ; B714798
        mov     ivtableh,ss                     ; B714798
        lea     ax,err1_ivtablel                ; B714798
        mov     ivtablel,ax                     ; B714798
        mov     ivcount,2                       ; B714798
        jmp     short yes_update                ; B714798
no_error_mid:                                   ; B714798
        mov     ivtableh,ss                     ; B714798
        lea     ax,err2_ivtablel                ; B714798
        mov     ivtablel,ax                     ; B714798
yes_update:                                     ; B714798
        add     cx,9                            ; B714798
        pop     si                              ; B714798
        pop     ds                              ; B714798
no_checking:                                    ; B714798
        mov     bx,cx                           ; DCR900
;                                               ; DCR900
ENDIF   ;FamilyAPI                              ; DCR900
;**************************************************************************
; The following code is common for both API.    ; DCR900
;**************************************************************************
;
        mov     ax,ivtableh                     ;address of ivtable
        push    ax
        mov     ax,ivtablel
        push    ax
        push    ivcount                         ;ivcount
        push    ds                              ;address of msg text
        push    si
        push    bx                              ;msg length
        mov     ax,dataareah                    ;address of dataarea
        push    ax
        mov     ax,dataareal
        push    ax
        push    datalength                      ;datalength
        mov     ax,msglengthh                   ;address of msglength
        push    ax
        mov     ax,msglengthl
        push    ax
        CALL    DOSINSMESSAGE

        mov     sys_error,ax                    ;save return code

IFNDEF  FamilyAPI                               ; DCR900
goback:                                         ; DCR900
        mov     ax,iseg                         ; DCR900
        mov     ds,ax                           ; DCR900
        assume  ds:iseg                         ; DCR900
ENDIF   ;FamilyAPI                              ; DCR900

copyret:                                        ; @@@@
                RET
COPYRETMSG      ENDP
;********************************
        SUBTTL DecDump Routine
        PAGE
;/********************** START OF SPECIFICATIONS *********************/
;/* SUBROUTINE NAME:  DECDUMP                                        */
;/*                                                                  */
;/* DESCRIPTIVE NAME:  CONVERTS MESSAGE ID TO ASCII                  */
;/*                                                                  */
;/* FUNCTION: CONVERTS BINARY MESSAGE ID TO A PRINTABLE ASCII        */
;/*           VALUE. THIS NUMBER WILL BE RETURNED WHEN THE FOLLOWING */
;/*           ERRORS ARE RETURNED BY DOSGETMESSAGE OR DOSINSMESSAGE: */
;/*                                                                  */
;/*           ERROR_MR_UN_PERFORM                                    */
;/*           ERROR_MR_MID_NOT_FOUND                                 */
;/*           ERROR_MR_INV_MSGF_FORMAT                               */
;/*           ERROR_MR_INV_IVCOUNT                                   */
;/*                                                                  */
;/* NOTES:  NONE                                                     */
;/*                                                                  */
;/* RESTRICTIONS: NONE                                               */
;/*                                                                  */
;/* ENTRY POINT:  DECDUMP                                            */
;/*    LINKAGE:   CALL NEAR                                          */
;/*                                                                  */
;/* INPUT:  AX = MESSAGE ID                                          */
;/*             SI -> mid_string                                     */
;/*                                                                  */
;/* EXIT-NORMAL:  es:si ------> ASCII REPRESENTATION OF MESSAGE ID   */
;/*                                                                  */
;/* EXIT-ERROR:   NONE                                               */
;/*                                                                  */
;/* EFFECTS:  NONE                                                   */
;/*                                                                  */
;/* INTERNAL REFERENCES:                                             */
;/*    ROUTINES: NONE                                                */
;/*                                                                  */
;/* EXTERNAL REFERENCES:                                             */
;/*    ROUTINES: NONE                                                */
;/*********************** END OF SPECIFICATIONS **********************/
DecDump proc    near
        push    bx
        push    cx
        push    di
        push    si

        mov     bl,al                           ;save low byte of original number
        mov     cx,ss                           ;setup reg for string operations
        mov     es,cx
        mov     di,si                           ;get address of output string
        mov     al,' '                          ;store blank in al
        stosb                                   ;blank out 1rst char of output string
        mov     cx,4                            ;length of 4
        mov     al,'0'                          ;store '0' in al
rep     stosb                                   ;'zero' out output string
        mov     byte ptr es:[di],0              ;put zero at end of string
        add     si,5                            ;setup pointer to end of buffer
        mov     al,bl                           ;restore original low byte
        mov     cx,10                           ;cx = 10
dec_loop:
        dec     si                              ;move pointer back 1
        xor     dx,dx                           ;clear dx
        div     cx                              ;divide by ten
        add     dl,'0'                          ;convert to ascii
        mov     byte ptr es:[si],dl             ;save character in buffer
        or      ax,ax                           ;test for quotient = 0
        jnz     dec_loop                        ;jump if still a quotient
        pop     si                              ;get address of output string

        pop     di
        pop     cx
        pop     bx

        ret                                     ;else return to caller
DecDump endp
;********************************
        SUBTTL CopyMsgHd        Routine
        PAGE
;/********************** START OF SPECIFICATIONS *********************/
;/* SUBROUTINE NAME:  COPYMSGHD                                      */
;/*                                                                  */
;/* DESCRIPTIVE NAME:  COPY MESSAGE HEADER                           */
;/*                                                                  */
;/* FUNCTION: COPIES THE COMPONENT ID AND MESSAGE NUMBER AT START    */
;/*           OF CALLERS BUFFER and calls DOSINSMESSAGE              */
;/*                                                                  */
;/* NOTES:  NONE                                                     */
;/*                                                                  */
;/* RESTRICTIONS: NONE                                               */
;/*                                                                  */
;/* ENTRY POINT:  COPYMSGHD                                          */
;/*    LINKAGE:   CALL NEAR                                          */
;/*                                                                  */
;/* INPUT:     AX = msg number                                       */
;/*                                                                  */
;/* EXIT-NORMAL:                                                     */
;/*               datalength = datalength - 9                        */
;/*               databuffer = databuffer + 9                        */
;/*                                                                  */
;/* EXIT-ERROR:                                                      */
;/*               return from DosInsMessage =                        */
;/*                                                                  */
;/*      AX= error_mr_message_too_long                               */
;/*                                                                  */
;/* EFFECTS:  adjusts callers buffer length and pointer to callers   */
;/*           buffer.                                                */
;/* INTERNAL REFERENCES:                                             */
;/*    ROUTINES:        Decdump                                      */
;/*                                                                  */
;/* EXTERNAL REFERENCES:                                             */
;/*    ROUTINES: DOSINSMESSAGE                                       */
;/*********************** END OF SPECIFICATIONS **********************/
COPYMSGHD  PROC    NEAR

        push    ds
        push    si
        push    bx
        push    cx
;
        cmp     default_root,1                  ;check if default root
        jnz     go_convert                      ;no
        push    es                              ;setup string transfer
        push    ss
        pop     es
        lea     di,component                    ;yes, change component ID
        push    ss
        pop     ds
        lea     si,ROOT_COMPONENT
        mov     cx,component_length
        rep     movsb
        pop     es
go_convert:
;
;       setup component id, message id and ': ' string
;
        lea     si,mid_string
call_dec:
        call    decdump                         ;convert msg id to ascii
;
;       store message id component field
;
;BD002; cmp     sav_error,error_mr_un_acc_msgf  ;B714798
;BD002; jnz     fill_rest                       ;B714798
;BD028; .if     <[msr_error] ne error_mr_un_acc_msgf> or  ;BN002;
;BD028; .if     <[sav_error] eq error_mr_un_acc_msgf> or  ;BN002;

        .if     <[msr_error] ne 0>              ;BC028; ;BN002;
          lea     di,component                  ;B714798
          mov     byte ptr es:[di],'S'          ;B714798
          mov     byte ptr es:[di+1],'Y'        ;B714798
          mov     byte ptr es:[di+2],'S'        ;B714798
        .endif

;BD002; fill_rest:

        lea     di,component+3          ;es:di -> msg id field in component
        lea     si,mid_string+1         ;es:si -> converted msg id
        mov     ax,es
        mov     ds,ax                   ;ds:si -> converted msg id
        mov     cx,4                    ;msg id length
rep     movsb                           ;copy msg id

;
;       store ': '
;
        mov     ax,' :'
        stosw

;
;       call    dosinsmessage to copy message header into callers buffer
;
IFNDEF  FamilyAPI
        push    0                               ;address of ivtable
        push    0
        push    0                               ;ivcount = 0
ELSE
        xor     ax,ax
        push    ax
        push    ax
        push    ax
ENDIF   ;FamilyAPI

        push    ss                              ;address of msginput
        lea     si,component
        push    si

IFNDEF  FamilyAPI
        push    9                               ;msginlength = 9
ELSE
        mov     ax,9
        push    ax
ENDIF   ;FamilyAPI

        mov     ax,dataareah                    ;address of dataarea
        push    ax
        mov     ax,dataareal
        push    ax
        push    datalength                      ;datalength
        mov     ax,msglengthh                   ;address of msglength
        push    ax
        mov     ax,msglengthl
        push    ax
        CALL    DosInsMessage
        mov     sys_error,ax
        or      ax,ax
        jnz     copyhd_done
;
;       if successful, then adjust callers buffer address
;                                  callers buffer length
;
        add     dataareal,9
        sub     datalength,9
;
copyhd_done:
        pop     cx
        pop     bx
        pop     si
        pop     ds

        RET

COPYMSGHD  ENDP
;********************************
        SUBTTL DO_Open          Routine
        PAGE
;/********************** START OF SPECIFICATIONS *********************/
;/* SUBROUTINE NAME:  DO_OPEN                                        */
;/*                                                                  */
;/* DESCRIPTIVE NAME:  Performs the DOSOPEN call to open the message */
;/*                               file.                              */
;/* FUNCTION: Sets up for and calls DosOpen to open the message file.*/
;/*                                                                  */
;/* NOTE:                                                            */
;/*                                                                  */
;/* RESTRICTIONS: NONE                                               */
;/*                                                                  */
;/* ENTRY POINT:  DO_OPEN                                            */
;/*    LINKAGE:   CALL NEAR                                          */
;/*                                                                  */
;/* INPUT:                                                           */
;/*                ES:DI -> filename to be opened                    */
;/*                                                                  */
;/* EXIT-NORMAL:                                                     */
;/*               AX = 0                                             */
;/*                                                                  */
;/* EXIT-ERROR:                                                      */
;/*               AX = error code                                    */
;/*                                                                  */
;/* EFFECTS:  uses AX                                                */
;/*                                                                  */
;/* INTERNAL REFERENCES:                                             */
;/*    ROUTINES: NONE                                                */
;/*                                                                  */
;/* EXTERNAL REFERENCES:                                             */
;/*    ROUTINES: DosOpen                                             */
;/*********************** END OF SPECIFICATIONS **********************/
PUBLIC DO_OPEN                                          ;@1 SDD
DO_OPEN    PROC    NEAR

JUST_OPEN:
;
;|1<--     CALL DOSOPEN - OPEN FILE;
;
        CLC                             ;CLEAR CARRY
        PUSH    ES                      ;PUSH @FILENAME
        PUSH    DI
;;;;;DCR361
        cmp     subfile_flag,0          ;check which file handle to use
        jz      rootit
        lea     ax,sub_handle           ;use sub file handle
        jmp     subit
rootit:
        LEA     AX,HANDLE               ;PUSH @HANDLE
subit:
;;;;;;;;;;;
        PUSH    SS
        PUSH    AX
        LEA     AX,ACTIONTAKEN          ;PUSH @ACTIONTAKEN
        PUSH    SS
        PUSH    AX
        XOR     AX,AX                   ;PUSH FILESIZE (ASSUME DON'T CARE??)
        PUSH    AX
        PUSH    AX
        PUSH    AX                      ;PUSH ATTRIBUTE (ASSUME DON'T CARE??)
IFDEF   FamilyAPI
        mov     ax,1
        push    ax
ELSE
        PUSH    1                       ;PUSH OPENFLAG (OPEN/CREATE)
ENDIF   ;FamilyAPI
        MOV     AX,OPENMODE             ;PUSH OPENMODE (DENY WRITE)
        PUSH    AX
        XOR     AX,AX                   ;PUSH   RESERVED DWORD
        PUSH    AX
        PUSH    AX
        CALL    DOSOPEN

        RET

DO_OPEN    ENDP
;********************************

IFNDEF  FamilyAPI
        SUBTTL Open_Dpath       Routine
        PAGE
;/********************** START OF SPECIFICATIONS *********************/
;/* SUBROUTINE NAME:  OPEN_DPATH                                     */
;/*                                                                  */
;/* DESCRIPTIVE NAME:  searches for message file                     */
;/*                                                                  */
;/* FUNCTION: calls DosSearchPath to find message file. If found,    */
;/*           the message is opened via Do_Open.                     */
;/* NOTE:                                                            */
;/*                                                                  */
;/* RESTRICTIONS: NONE                                               */
;/*                                                                  */
;/* ENTRY POINT:  OPEN_DPATH                                         */
;/*    LINKAGE:   CALL NEAR                                          */
;/*                                                                  */
;/* INPUT:                                                           */
;/*            ES:DI -> filename only                                */
;/*                                                                  */
;/* EXIT-NORMAL:                                                     */
;/*               AX = 0                                             */
;/*                                                                  */
;/* EXIT-ERROR:                                                      */
;/*               AX = error code                                    */
;/*                                                                  */
;/* EFFECTS:  uses AX                                                */
;/*                                                                  */
;/* INTERNAL REFERENCES:                                             */
;/*    ROUTINES: Do_Open                                             */
;/*                                                                  */
;/* EXTERNAL REFERENCES:                                             */
;/*    ROUTINES: DosSearchPath                                       */
;/*              DosAllocseg                                         */
;/*              DosFreeseg                                          */
;/*********************** END OF SPECIFICATIONS **********************/
PUBLIC OPEN_DPATH                       ;@1 SDD
OPEN_DPATH PROC    NEAR

        push    es                      ;save address of filename
        push    di

        mov     ax,iseg
        mov     ds,ax
        assume  ds:iseg
;
;       allocate search path buffer
;
        push    asciiz_len              ;push size max path length
        push    ss                      ;push selector
        lea     ax,search_sel           ;ax = offset of selector
        push    ax                      ;push offset
        PUSH    0                       ;NOT SHARED
        call    DosAllocSeg

        or      ax,ax                   ;ok ?
        jz      go_search               ;yes, search path
        mov     sys_error,error_mr_un_perform  ;else set error code
        jmp     end_dpath               ; and return
;
;       call    dossearchpath
;
go_search:
        push    7                       ; control word (path source='DPATH')
                                        ; (implied current bit=search current dir)
                                        ; and ignore network errors
        push    ds
        mov     ax,offset dpath_str     ; search path reference
        push    ax
        push    es
        push    di                      ; file name
        push    search_sel
        push    0                       ; search result buffer
        push    asciiz_len              ; search buffer length
        call    dossearchpath

        or      ax,ax                   ; error ?
        jz      go_open                 ; no, go do_open
        jmp     err_dpath               ; and exit
;
;       open file
;
go_open:
        mov     ax,search_sel           ;
        mov     es,ax                   ;
        xor     di,di                   ; es:di -> result filename
        call    do_open                 ;

err_dpath:

        push    ax                      ; save error return
        push    search_sel
        call    dosfreeseg
        pop     ax                      ; restore error return
PUBLIC end_dpath                                ;@1 SDD
end_dpath:
        pop     di
        pop     es
        RET

OPEN_DPATH ENDP
ENDIF   ; FamilyAPI
;********************************
        SUBTTL Xfer_Filename    Routine
        PAGE
;/********************** START OF SPECIFICATIONS *********************/
;/* SUBROUTINE NAME:  XFER_FILENAME                                  */
;/*                                                                  */
;/* DESCRIPTIVE NAME:  stuffs boot drive into file name buffer       */
;/*                                                                  */
;/* FUNCTION: stuffs boot drive and ':' into file name buffer        */
;/*                                                                  */
;/* NOTE:                                                            */
;/*                                                                  */
;/* RESTRICTIONS: NONE                                               */
;/*                                                                  */
;/* ENTRY POINT:  XFER_FILENAME                                      */
;/*    LINKAGE:   CALL NEAR                                          */
;/*                                                                  */
;/* INPUT:                                                           */
;/*                ES = iseg                                         */
;/*            BX = length of input filename                         */
;/*            CX = boot drive letter (or 0 if none)                 */
;/* EXIT:                                                            */
;/*                                                                  */
;/*            es:di -> drive:\filename                              */
;/*            temp -> contains 3 characters stomped by C:\          */
;/*                                                                  */
;/* EFFECTS:      none                                               */
;/*                                                                  */
;/* INTERNAL REFERENCES:                                             */
;/*    ROUTINES: none                                                */
;/*                                                                  */
;/* EXTERNAL REFERENCES:                                             */
;/*    ROUTINES:                                                     */
;/*********************** END OF SPECIFICATIONS **********************/
XFER_FILENAME PROC    NEAR

assume  ds:iseg
        push    bx                              ; save bx
        sub     di,3                            ; get room for C:\
        mov     bx, es:[di]                     ; save actual string in temp
        mov     word ptr ds:temp, bx            ; save first 2 bytes
        mov     bl, es:[di+2]
        mov     ds:temp[2], bl                  ; save last byte
        mov     es:[di], cx                     ; copy drive: into it
        mov     byte ptr es:[di+2], '\'         ; put in \
        pop     bx                              ; restore bx
        RET

XFER_FILENAME ENDP
;********************************
        SUBTTL Test_Open_Err    Routine
        PAGE
;/********************** START OF SPECIFICATIONS *********************/
;/* SUBROUTINE NAME:  TEST_OPEN_ERR                                  */
;/*                                                                  */
;/* DESCRIPTIVE NAME:  test for acceptable errors                    */
;/*                                                                  */
;/* FUNCTION: Looks through the valid error table to see if we       */
;/*           should continue to search or not.                      */
;/*                                                                  */
;/* NOTE:                                                            */
;/*                                                                  */
;/* RESTRICTIONS: NONE                                               */
;/*                                                                  */
;/* ENTRY POINT:  TEST_OPEN_ERR                                      */
;/*    LINKAGE:   CALL NEAR                                          */
;/*                                                                  */
;/* INPUT:                                                           */
;/*            AX = error code                                       */
;/* EXIT:                                                            */
;/*                CY = 1 -> NOT acceptable error or no error        */
;/*            CY = 0 -> if error code eq. one of the above          */
;/*                                                                  */
;/* EFFECTS:      Flags                                              */
;/*                                                                  */
;/* INTERNAL REFERENCES:                                             */
;/*    ROUTINES: none                                                */
;/*                                                                  */
;/* EXTERNAL REFERENCES:                                             */
;/*    ROUTINES:                                                     */
;/*********************** END OF SPECIFICATIONS **********************/
TEST_OPEN_ERR PROC    NEAR

        or      ax, ax                  ; check for error, if none leave
        jz      err_exit

        push    es                      ; save current ES and DI
        push    di
        mov     cx,msgseg               ; have ES point to msgseg
        mov     es,cx
        mov     di, offset ValidErrs    ; get offset of error table
        mov     cx, ErrCount            ; load in count

        repnz   scasw                   ; look for error

        pop        di                      ; restore ES and DI
        pop     es
        jnz     err_exit                ; error not found in list
        clc                             ; else, error found so clear carry
        jmp     test_1
err_exit:
        stc                             ; set carry
PUBLIC test_1                           ;@1 SDD
test_1:
        RET                             ; all done

TEST_OPEN_ERR   ENDP
;********************************

IFNDEF  FamilyAPI
        SUBTTL MSGTRACE         Routine
        PAGE
;/************************* START OF SPECIFICATIONS ******************/
;/*    SUBROUTINE NAME:   MSGTRACE                                   */
;/*                                                                  */
;/*    DESCRIPTIVE NAME:  Message Retriever trace hooks              */
;/*                                                                  */
;/*    FUNCTION: This routine will first check if trace in enabled.  */
;/*              If it is enabled then the appropriate information   */
;/*              will be setup and DosSysTrace will be called.       */
;/*                                                                  */
;/*    NOTES:    no error checking is done on the DosSysTrace call   */
;/*              Tracing is only valid in Protect mode.              */
;/*                                                                  */
;/*    ENTRY POINT:  MSGTRACE                                        */
;/*       LINKAGE:  near call                                        */
;/*                                                                  */
;/*    INPUT:  passed on user stack                                  */
;/*                                                                  */
;/*            MinorTraceCode  = word  - minor trace code            */
;/*            Parm3           = word  - 3rd parm  /pushed 1rst      */
;/*            Parm2           = word  - 2nd parm  /  "    2nd       */
;/*            Parm1           = word  - 1rst parm /  "    last      */
;/*                                                                  */
;/*     The reason the parameters pushed should be pushed in the     */
;/*     reverse order, is that SS:SP points to the LAST parameter    */
;/*     passed when entring this routine.                            */
;/*     If the parameter is not used, then it should be zero.        */
;/*                                                                  */
;/*    EXIT-NORMAL: none                                             */
;/*    EXIT-ERROR:  none                                             */
;/*                                                                  */
;/*    INTERNAL REFERENCES: NONE                                     */
;/*                                                                  */
;/*    EXTERNAL REFERENCES:                                          */
;/*                         DosAllocseg - get buffer to copy filename*/
;/*                         DosSysTrace - store system trace record  */
;/*                         DosFreeSeg  - free buffer                */
;/************************** END OF SPECIFICATIONS *******************/
PROCEDURE MSGTRACE,NEAR

Argvar          Parm1,WORD                      ; parameters passed for
Argvar          Parm2,WORD                      ;  each event
Argvar          Parm3,WORD                      ;    to be traced
Argvar          MinorCode,WORD                  ; minor code for tracing

LocalVar        lngth,WORD                      ; length of buffer
LocalVar        buffselector,WORD               ; buffer selector
LocalVar        buffoffset,WORD                 ; offset of buffer

        ENTERPROC                       ;SETUP BP
        pusha
        push    es
        push    ds

; major code  = TraceCode_Message
; SIS_mec_table - RAS Major Event Code table in InfoSeg

        mov     ax,initseg              ;Get addressability to initseg
        mov     ds,ax

        assume  ds:initseg

        mov     ax,globalseg
        mov     ds,ax                   ; ds -> start of global segment
        test    Ds:SIS_mec_table+(TraceCode_Message SHR 3), 80h SHR (TraceCode_Message AND 7)
        jnz     t2                      ; trace = ON
        jmp     exit                    ; exit if trace = off
t2:

; Test to see if performance tracing is enabled

IFDEF   MMIOPH                          ;@@1
        test    Ds:SIS_mec_table+(PERFTRACE SHR 3), 80h SHR (PERFTRACE AND 7)   ; see if perf tracing enabled
        jz      skipperf                ;Regular trace, not perf
        push    ds:SIS_MMIOBase         ;init ES to point to Dekko seg
        pop     es
        mov     AH,TraceCode_message    ;set up major/minor trace code
        mov     BX,MinorCode
        mov     AL,BL
        mov     es:[MAJMIN_CODE],AX     ;store in Dekko address

        .if     <bl EQ TraceCode_PreGetMessage>         ;BC011; Pre-Get?
          mov     ax,parm1                                    ; message number
          mov     es:[PERF_DATA],ax
          mov     ax,parm3                                    ; filename segment
          mov     ds,ax
          mov     si,parm2                                    ; filename offset
          .repeat                                       ;BC011;
            lodsw                                             ; filename to
            mov     es:[PERF_DATA],ax                         ;  DEKKO buffer
          .until  <ZERO ah> OR                          ;BC011;   2 bytes
          .until  <ZERO al>                             ;BC011;    at a time

        .elseif <bl EQ TraceCode_PreInsMessage>  OR     ;BC011; ivcount, msglen
        .if     <bl EQ TraceCode_PrePutMessage>  OR     ;BC011; handle,  msglen
        .if     <bl EQ TraceCode_PostGetMessage> OR     ;BC011; msglen,  RC
        .if     <bl EQ TraceCode_PostInsMessage>        ;BC011; msglen,  RC
          mov     ax,parm1
          mov     es:[PERF_DATA],ax                           ;stuff in parm1
          mov     ax,parm2
          mov     es:[PERF_DATA],ax                           ;stuff in parm2

        .elseif <bl EQ TraceCode_PostPutMessage> OR     ;BC011; RC
        .if     <bl EQ TraceCode_PostQryMessage>        ;BC011; RC
          mov     ax,parm1
          mov     es:[PERF_DATA],ax                           ; B713044

        .endif                                          ;BN011;

        jmp     exit                            ; B713044

ENDIF  ;MMIOPH                           @@1

;
; *********************************************************************
;
;       TRACE = ON, so must setup for appropriate event and call DosSysTrace
;
; **********************************************************
;
;       ASSUME that all parameters are on stack, starting with parm1
;
skipperf:
        mov     buffselector,ss ; set buffer selector
        lea     ax, parm1       ; set buffer offset
        mov     buffoffset, ax  ;   to start of parameter list

; ************************************************************
;
;   Pre-Invocation trace for DosGetMessage event
;
        cmp     MinorCode,TraceCode_PreGetMessage
        jnz     next1
;
;       for Pre-DosGetMessage, parm1 = MsgNumber
;                              parm2 = Filename offset
;                              parm3 = Filename selector
;

        mov     di,parm2
        mov     es,parm3                        ;es:di -> input filename

;       calculate filename length

        mov     dx,di                           ;save input filename offset
        mov     al,0                            ;check for eostring
        mov     cx,asciiz_len                   ;cx = max asciiz len
        repne   scasb                           ;scan til eostring
        mov     bx,asciiz_len                   ;get max asciiz len
        sub     bx,cx                           ;bx: string length
        mov     cx,bx                           ;cx = bx

;       get buffer to copy filename into

        add     bx,2                    ;buffer size = msgnumber + filename
        push    bx                      ;push   buffer length
        lea     ax,buffselector         ;push @selector
        push    ss
        push    ax
        push    0                       ;not shared
        call    dosallocseg
        or      ax,ax
        jz      t3
        jmp     exit
t3:
        mov     di,dx                           ;es:di -> file name
        push    es
        push    di

        mov     ax, buffselector                ;es:di -> buffer
        mov     es, ax                          ;
        xor     di,di                           ;

        pop     si                              ;
        pop     ds                              ;ds:si -> file name


;       Fisrt copy MsgNumber into buffer

        mov     ax, parm1
        stosw

;       Now, copy file name into buffer

        rep     movsb

        mov     lngth, bx
        mov     buffoffset, 0   ; buffer at buffselector:0
        jmp     short CallTrace

; **********************************************************
;
;   Post-Invocation trace for DosGetMessage event
;
next1:  cmp     MinorCode,TraceCode_PostGetMessage
        jnz     next2
;
;       for Post-DosGetMessage, parm1 = Return code
;                               parm2 = Msg length
;                               parm3 = 0
;
        mov     lngth,4         ; set length = word
        jmp     short CallTrace

; **********************************************************
;
;   Pre-Invocation trace for DosInsMessage event
;
next2:  cmp     MinorCode,TraceCode_PreInsMessage
        jnz     next3
;
;       for Pre-DosInsMessage, parm1 = IvCount
;                              parm2 = Msg length
;                              parm3 = 0
;
        mov     lngth,4         ; set length = word
        jmp     short CallTrace

; **********************************************************
;
;   Post-Invocation trace for DosInsMessage event
;
next3:  cmp     MinorCode,TraceCode_PostInsMessage
        jnz     next4
;
;       for Post-DosInsMessage, parm1 = Return code
;                               parm2 = Msg length
;                               parm3 = 0
;
        mov     lngth,4         ; set length = word
        jmp     short CallTrace

; **********************************************************
;
;   Pre-Invocation trace for DosPutMessage event
;
next4:  cmp     MinorCode,TraceCode_PrePutMessage
        jnz     next5
;
;       for Pre-DosPutMessage, parm1 = File handle
;                              parm2 = Msg length
;                              parm3 = 0
;
        mov     lngth,4         ; set length = word
        jmp     short CallTrace

; **********************************************************
;
;   Post-Invocation trace for DosPutMessage event
;
next5:  cmp     MinorCode,TraceCode_PostPutMessage
        jnz     exit
;
;       for Post-DosPutMessage, parm1 = Return Code
;                               parm2 = 0
;                               parm3 = 0

        mov     lngth,2         ; set length = word
;
;       falls thru to DosSysTrace call !!
;
; ***********************************************************

CallTrace:

;       CAll to DosSysTrace here !!
;
        push    TraceCode_Message               ; major code
        push    lngth                           ; buffer length
        push    MinorCode                       ; minor code
        push    buffselector                    ; buffer selector
        push    buffoffset                      ; buffer offset
        call    DosSysTrace

        cmp     MinorCode, TraceCode_PreGetMessage      ; if != PreDosGetMessage
        jnz     exit                                    ; then exit

        push    buffselector                            ; else free
        call    DosFreeSeg                              ;       buffer

exit:
        pop     ds
        pop     es
        popa

        LEAVE
        ret     8

MSGTRACE        ENDP
ENDIF   ;FamilyAPI
;***************************************************************************

code            ENDS
                END
