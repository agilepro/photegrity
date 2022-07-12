/********************************************************************************
 *                                                                              *
 *  COPYRIGHT (C) 1997-2002 FUJITSU SOFTWARE CORPORATION.  ALL RIGHTS RESERVED. *
 *                                                                              *
 ********************************************************************************/
package com.fujitsu.iflow.common;

import java.io.Serializable;
import java.util.HashMap;
import java.util.Locale;
import java.util.MissingResourceException;
import java.util.ResourceBundle;

/*******************************************************************************
 * This class is used to manage errorMessages text. The messages are stored in a
 * text file with the format:
 * 
 * <pre>
 *       token = This is the message for 'token'.
 * </pre>
 * 
 * First is an ID token, then an = sign, then the message. White space on either
 * end of the message is trimmed off. The message must not be longer than a
 * single line. Messages can substitute parameters into the message: <$1>, <$2>
 * etc. Messages can embed a 'cause' message with the <$e> token.
 * 
 * Most of these tokens look like integers, but in fact they are strings Below
 * you see a list of integer constants for use with the constructor for
 * ModelException that takes an integer, but in fact that integer is internally
 * converted to a string. Since the integer is not a very mnemonic device, we
 * would like to change this some day to use a string. For example something
 * like:
 * 
 * <pre>
 * public static final String SERVER_ACCESS_PERMISSION_FAILED = &quot;ibpm.SERVER_ACCESS_PERMISSION_FAILED&quot;;
 * </pre>
 * 
 * Changing these static integer constants to static string constants, and the
 * fact that ModelExceptin is overloaded to take either a string or a int as the
 * message number parameter, means that there is almost no code change necessary
 * to make this change. But the advantage is that the entry in the message file
 * itself is far more mnemonic, looking like this
 * 
 * <pre>
 *       ibpm.SERVER_ACCESS_PERMISSION_FAILED = User '&lt;$0&gt;' is neither the assignee of the work item nor the owner of the process instance, and is not authorized to make a choice.
 * </pre>
 * 
 * The result: no more numbers that are hard to search for and remember! The
 * string value would be EXACTLY the same as the variable name, including the
 * same casing and underscores, so that if you look for this exact symbol you
 * will find it in the source without problem. This is future functionality but
 * in some cases you may see non-numeric error codes being used.
 * 
 * @publish extension
 */
public class ErrorMessage implements Serializable {

    private static final long serialVersionUID = 1L;
    // i-Flow Server and Adapters
    public static final int SERVER_ACCESS_PERMISSION_FAILED = 10000;
    public static final int UNABLE_TO_GET_NEXT_LIST = 10001;
    public static final int UNABLE_TO_FIND_PROCESS_DEFINITION = 10002;
    public static final int NO_PROCESS_DEFINITION_TRANSACTION = 10003;
    public static final int PROCESS_UNLOCK_FAILED = 10004;
    public static final int TRANSACTION_READ_FAILED = 10005;
    public static final int TRANSACTION_WRITE_FAILED = 10006;
    public static final int SAVE_FAILED = 10007;
    public static final int DATABASE_ACCESS_FAILED = 10008;
    public static final int GET_VERSION_RECORD_FAILED = 10009;
    public static final int HISTORY_CREATION_FAILED = 10010;
    public static final int RUNNING_PROCESS_START_FAILED = 10011;
    public static final int PROCESS_TYPE_DETERMINATION_FAILED = 10012;
    public static final int PROCESS_START_FAILED = 10013;
    public static final int TEMPLATE_ACTIVITY_ADD_FAILED = 10014;
    public static final int INVALID_ACTIVITY_INSTANCE = 10015;
    public static final int INVALID_ARROW_INSTANCE = 10016;
    public static final int XML_PARSING_FAILED = 10017;
    public static final int IDENTIFICATION_FAILED_ACTIVITY_ASSIGNEES = 10018;
    public static final int LOCKED_EDITING_PROCESS = 10019;
    public static final int DIFFERENT_ORIGINATION_ARROW = 10020;
    public static final int ARROW_DEFINITION_FAILED = 10021;
    public static final int MAKECHOICE_EVENT_FAILED = 10022;
    public static final int SERVER_ADD_ATTACHMENT_FAILED = 10023;
    public static final int DELETE_ATTACHMENT_FAILED = 10024;
    public static final int FIND_ATTACHMENT_FAILED = 10025;
    public static final int JAVAACTIONSET_XML_PARSING_FAILED = 10026;
    public static final int JAVAACTIONSET_INVALID_ATTRIBUTES = 10027;
    public static final int DELETE_ACTIVITY_ATTACHMENT_FAILED = 10028;
    public static final int UNRECOGNIZED_PARMS_IN_IFLOW_PROPERTIES = 10029;
    public static final int JAVAACTION_XML_PARSING_FAILED = 10030;
    public static final int JAVAACTION_INVALID_ATTRIBUTES = 10031;
    public static final int ERROR_CHECKING_LOCK = 10032;
    public static final int SERVER_CREATE_PROCESS_INSTANCE_FAILED = 10033;
    public static final int USERID_ALREADY_EXISTS = 10034;
    // Commenting this Error Constant(10035). Refer bug 3766.
    // public static final int SUSPENDED_PROCESS_EDIT_FAILED = 10035;
    public static final int RESUME_NONSUSPENDED_PROCESS_FAILED = 10036;
    public static final int FIND_DATASET_FAILED = 10037;
    public static final int EDIT_ENACTMENT_FAILED = 10038;
    public static final int CANCEL_EDIT_ENACTMENT_FAILED = 10039;
    public static final int LOCKED_ENACMENT_OPERATION_FAILED = 10040;
    public static final int INVALID_OR_MISSING_USERID = 10041;
    public static final int CANNOT_LOCATE_REQUESTED_FIELD_TYPE = 10042;
    public static final int ENACTMENT_PROCESS_NEEDS_LOCK = 10043;
    public static final int COULD_NOT_CREATE_UDA = 10044;
    public static final int TYPE_MATCHING_FAILED = 10045;
    public static final int NOT_AND_OR_ACTIVITY_NODE = 10046;
    public static final int THRESHOLD4_MEMORY_ALLOCATION_FAILED = 10047;
    public static final int THRESHOLD3_MEMORY_ALLOCATION_FAILED = 10048;
    public static final int OBJECT_REFERENCE_FAILED = 10049;
    public static final int COULD_NOT_UPDATE_UDA = 10050;
    public static final int ACTIVATE_ON_AND_NODE_FAILED = 10051;
    public static final int ACTIVATE_RUNNING_ACTIVITY_FAILED = 10052;
    public static final int DEACTIVATE_INACTIVE_PROCESS_FAILED = 10053;
    public static final int NODE_DOES_NOT_SUPPORT_DEACTIVATION = 10054;
    public static final int SERVER_ACTIVATE_NODE_INSTANCE_FAILED = 10055;
    public static final int DEACTIVATE_NODE_INSTANCE_FAILED = 10056;
    public static final int DELETE_ACTIVITY_INSTANCE_FAILED = 10057;
    public static final int MODIFY_ACTIVITY_INSTANCE_FAILED = 10058;
    public static final int ADD_ARROW_FAILED_NO_SOURCE_TARGET = 10059;
    public static final int MARK_WORKITEM_READ_FAILED = 10060;
    public static final int DELETE_ARROW_FAILED = 10061;
    public static final int FAILED_TO_CLONE_NAMEVALUESET = 10062;
    public static final int SERVER_MODIFY_ARROW_INSTANCE_FAILED = 10063;
    public static final int MODIFY_PROCESS_INSTANCE_FAILED = 10064;
    public static final int MODIFY_FORM_LIST_FAILED = 10065;
    public static final int NOT_IMPLEMENTED_METHOD_CALL = 10066;
    public static final int COULD_NOT_GET_FORM_LIST = 10067;
    public static final int UNABLE_TO_CONVERT_DATA_TO_BYTE_ARRAY = 10068;
    public static final int CANNOT_SUSPEND_WORKITEM = 10069;
    public static final int COULD_NOT_CONVERT_BYTE_ARRAY_TO_STRUCTURE = 10070;
    public static final int COULD_NOT_UPDATE_PROCESS_INSTANCE = 10071;
    public static final int COULD_NOT_EDIT_THE_PROCESS_INSTANCE = 10072;
    public static final int COULD_NOT_FIND_ACTIVITY_TYPE = 10073;
    public static final int COULD_NOT_FIND_THE_SUBPROCESS = 10074;
    public static final int COULD_NOT_GET_PROCESS_DATASET = 10075;
    public static final int UNABLE_TO_ABORT_SUBPROCESS = 10076;
    public static final int UNABLE_TO_ABORT_THE_PROCESS = 10077;
    public static final int COULD_NOT_RETRIEVE_PROCESS_DEFINITION = 10078;
    public static final int COULD_NOT_PERFORM_NODE_TASK = 10079;
    public static final int ACTIVITY_HAS_INVALID_STATE = 10080;
    public static final int INVALID_USE_OF_OBJECTID_RANGE = 10081;
    public static final int ABORT_ONLY_BY_OWNER_OR_ADMIN = 10082;
    public static final int INVALID_SERVER_MEMORY_ZONE_SIZES = 10083;
    public static final int INVALID_MAX_MEMORY_SIZE_REQUEST = 10084;
    public static final int INVALID_HOUSEKEEPING_MEMORY_SIZE = 10085;
    public static final int INVALID_MEMORY_MONITOR_FREQUENCY = 10086;
    public static final int INVALID_GARBAGE_COLLECTION_FREQUENCY = 10087;
    public static final int INVALID_HEARTBEAT_VALUE = 10088;
    public static final int OPTION_ARROW_NOT_FOUND = 10089;
    public static final int FAILED_TO_UPDATE_UDA_VALUE = 10090;
    public static final int RECEIVED_SWAP_EXCEPTION = 10091;
    public static final int CREATE_REMOTE_SUBPROCESS_FAILED = 10092;
    public static final int SEND_SUBPROCESS_COMPLETE_FAILED = 10093;
    public static final int COULD_NOT_COMPLETE_REMOTE_SUBPROCESS_ACTIVITY = 10094;
    public static final int PUBLISHED_DRAFT_PLAN_NOT_FOUND = 10095;
    public static final int UNEXPECTED_NULL_EXCEPTION = 10096;
    public static final int NULL_PARAMETER_EXCEPTION = 10097;
    public static final int CREATE_ASAP_REMOTE_SUBPROCESS_FAILED = 10098;
    public static final int SEND_ASAP_SUBPROCESS_COMPLETE_FAILED = 10099;
    public static final int UNABLE_TO_GET_DATA_FROM_XML_DUE_TO_INVALID_ATTRIBUTE_LIST = 10100;

    public static final int USER_NOT_LOGGED_IN = 10101;
    public static final int CREATE_NAME_COMPONENT_FAILED = 10102;
    public static final int TIMER_XML_PARSING_FAILED = 10103;
    public static final int TIMER_INVALID_ATTRIBUTES = 10104;
    public static final int SERVER_LOGIN_FAILED = 10105;
    public static final int MISSING_ATTRIBUTE = 10106;
    public static final int TIMER_TASK_REQUEST_UNRECOGNIZED = 10107;
    public static final int FILELIST_XML_PARSING_FAILED = 10108;
    public static final int SESSION_CREATION_FAILED = 10109;
    public static final int INVALID_USER_NAME = 10110;
    public static final int INVALID_ADMIN_USER = 10111;
    public static final int ERROR_IN_LOGIN = 10112;
    public static final int UNRESOLVED_ROLE = 10113;
    public static final int PROCESS_LOCATION_FAILED = 10114;
    public static final int UNRESOLVED_TWFTEMPLATEPUBLISHER = 10115;
    public static final int UNAUTHORIZED_TWFTEMPLATEPUBLISHER = 10116;
    public static final int NO_ACTIVITY_ROLE_ACTION_SCRIPT_FOUND = 10117;
    public static final int UNAUTHORIZED_PROCESS_OWNER = 10118;
    public static final int PROPERTY_NOT_SPECIFIED = 10119;
    public static final int NO_ADMINISTRATOR_ROLE_FOUND = 10120;
    public static final int SERVER_INITIALIZATION_FAILED = 10121;
    public static final int DBADAPTER_INITIALIZATION_FAILED = 10122;
    public static final int DIRADAPTER_INITIALIZATION_FAILED = 10123;
    public static final int DMSADAPTER_INITIALIZATION_FAILED = 10124;
    public static final int DDFRAMEWORKADAPTER_INITIALIZATION_FAILED = 10125;
    public static final int JSINTERPRETER_INITIALIZATION_FAILED = 10126;
    public static final int EMAILADAPTER_INITIALIZATION_FAILED = 10127;
    public static final int SMSADAPTER_INITIALIZATION_FAILED = 10128;
    public static final int SMSCONNECTOR_INITIALIZATION_FAILED = 10129;
    public static final int RMI_INITIALIZATION_FAILED = 10130;
    public static final int CORBA_INITIALIZATION_FAILED = 10131;
    public static final int NAMING_SERVICE_NOT_FOUND = 10132;
    public static final int NAMING_SERVICE_NO_ROOT_CONTEXT = 10133;
    public static final int NAMING_SERVICE_UNBIND_FAILED = 10134;
    public static final int NAMING_SERVICE_BIND_FAILED = 10135;
    public static final int NAMING_SERVICE_RESOLVE_FAILED = 10136;
    public static final int WAITING_FOR_ADAPTER = 10137;
    public static final int ADAPTER_VERSION_MISMATCH = 10138;
    public static final int DBADAPTER_LOGIN_FAILED = 10139;
    public static final int SERVER_ADAPTER_INITIALIZATION_STARTED = 10140;
    public static final int TRANSPORT_TYPE_RMI = 10141;
    public static final int DIRECTORY_TYPE_LDAP = 10142;
    public static final int DATABASE_URL = 10143;
    public static final int FORMS_AND_ATTACHMENTS_MAY_FAIL = 10144;
    public static final int FILE_SEPARATOR_ENVIRONMENT = 10145;
    public static final int WEB_AND_FTP_SERVER_NOT_ON_SAME_HOST = 10146;
    public static final int FTP_AND_DMS_MUST_BE_ON_SAME_HOST = 10147;
    public static final int FTP_NOT_ENABLED_FOR_WRITE_ACCESS = 10148;
    public static final int REQUIRED_DIRECTORY_ATTRIBUTES_MISSING = 10149;
    public static final int SERVER_READY = 10150;
    public static final int ADAPTER_READY = 10151;
    public static final int NO_WEB_CLIENT_DIRECTORY_FOUND = 10152;
    public static final int IFLOW_JAR_VERSION_MISMATCH = 10153;
    public static final int WINDOWS_LOGIN_API_ERROR = 10154;
    public static final int HOST_REQUIRED_RIGHTS_FOR_LOGIN_NOT_HELD = 10155;
    public static final int CLIENT_REQUIRED_RIGHTS_FOR_LOGIN_NOT_HELD = 10156;
    public static final int UNRECOGNIZED_USERID_OR_PASSWORD = 10157;
    public static final int UNABLE_TO_CREATE_LOG_FILE = 10158;
    public static final int LOGIN_FAILURE_WITH_LDAP = 10159;
    public static final int IFLOW_PARAMETER_ERRORS = 10160;
    public static final int CORRECT_SETUP_AND_RESTART_IFLOW = 10161;
    public static final int SERVER_ADAPTER_INITIALIZATION_FAILED = 10162;
    public static final int IO_ERROR_WRITING_LOG_FILE = 10163;
    public static final int IFLOW_PARAMETER_FILE_ERROR = 10164;
    public static final int EMAIL_ADDRESS_INVALID = 10165;
    public static final int ADAPTER_PARAMETERS_INVALID = 10166;
    public static final int EMAIL_SMS_REQUESTS_IGNORED = 10167;
    public static final int SMTP_SMS_SERVER_HOST = 10168;
    public static final int ENTER_PROMPT = 10169;
    public static final int MEMORY_MONITOR_HEADING = 10170;
    public static final int MEMORY_MONITOR_SESSION_HEARTBEAT = 10171;
    public static final int MEMORY_MONITOR_FREQUENCY = 10172;
    public static final int MEMORY_MONITOR_GARBAGE_COLLECTION = 10173;
    public static final int MEMORY_MONITOR_INITIAL_HEAP = 10174;
    public static final int MEMORY_MONITOR_THRESHOLD1 = 10175;
    public static final int MEMORY_MONITOR_THRESHOLD2 = 10176;
    public static final int MEMORY_MONITOR_THRESHOLD3 = 10177;
    public static final int MEMORY_MONITOR_HOUSEKEEPING = 10178;
    public static final int MEMORY_MONITOR_MEMORY_MAX = 10179;
    public static final int MEMORY_MONITOR_MEMORY_RECLAIMED = 10180;
    public static final int MEMORY_MONITOR_NO_HEARTBEAT_LOGOFF = 10181;
    public static final int MEMORY_MONITOR_GROUP_SEPARATOR = 10182;
    public static final int MEMORY_MONITOR_CURRENT_MEMORY_USED = 10183;
    public static final int MEMORY_MONITOR_FREE_MEMORY_ON_HEAP = 10184;
    public static final int MEMORY_MONITOR_MAX_MEMORY_AVAILABLE = 10185;
    public static final int MEMORY_MONITOR_EVENT_BUCKET_SIZE = 10186;
    public static final int MEMORY_MONITOR_LARGEST_EVENT_BUCKET = 10187;
    public static final int MEMORY_MONITOR_EVENT_THREADS = 10188;
    public static final int MEMORY_MONITOR_NOTIFICATION_QUEUE = 10189;
    public static final int MEMORY_MONITOR_NOTIFICATION_THREADS = 10190;
    public static final int MEMORY_MONITOR_DATABASE_CONNECTIONS = 10191;
    public static final int MEMORY_MONITOR_PROCESSES_IN_MEMORY = 10192;
    public static final int MEMORY_MONITOR_MEMORY_BELOW_THRESHOLD1 = 10193;
    public static final int MEMORY_MONITOR_USER_LOGGED_IN = 10194;
    public static final int MEMORY_MONITOR_USAGE_EXCEEDS_THRESHOLD = 10195;
    public static final int MEMORY_MONITOR_PROCESSES_PURGED = 10196;
    public static final int MEMORY_MONITOR_OUT_OF_MEMORY = 10197;
    public static final int UNABLE_TO_LOCATE_RESOURCES_IN_USE = 10198;
    public static final int EDIT_UNLOCK_PROCESS_FAILED = 10199;
    public static final int RELOCKING_LOCKING_TEMPLATE_FAILED = 10200;
    public static final int RETRIEVING_READ_TRANSACTION_FAILED = 10201;
    public static final int RETRIEVING_WRITE_TRANSACTION_FAILED = 10202;
    public static final int ANDJOIN_XML_PARSING_FAILED = 10203;
    public static final int EDIT_PUBLISHED_TEMPLATE_FAILED = 10204;
    public static final int CANCEL_TEMPLATE_EDIT_FAILED = 10205;
    public static final int COMMIT_TEMPLATE_EDIT_FAILED = 10206;
    public static final int INVALID_ARROW_ID = 10207;
    public static final int INVALID_DATA_PROCESS_CREATION_FAILED = 10208;
    public static final int PRIVATE_TEMPLATE_OPERATION_FAILED = 10209;
    public static final int REGISTER_PROCESS_INSTANCE_FAILED = 10210;
    public static final int START_PROCESS_FAILED = 10211;
    public static final int PROCESSDEFINITION_XML_PARSING_FAILED = 10212;
    public static final int DELETE_PUBLISHED_TEMPLATE_FAILED = 10213;
    public static final int INVALID_ACTIVITY_DEFINITION_ID_MISSING_ARROW = 10214;
    public static final int INVALID_ACTIVITY_DEFINITION_ID_MISSING_ACTIVITY = 10215;
    public static final int DELETE_PROCESS_FAILED_NOT_OWNER_OR_ADMIN = 10216;
    public static final int PROCESS_LOCKED_BY_OTHER = 10217;
    public static final int PROCESSINSTANCE_XML_PARSING_FAILED = 10218;
    public static final int COULD_NOT_FIND_OR_READ_IFLOW_PROPERTIES = 10219;
    public static final int COULD_NOT_GENERATE_VALID_IDS = 10220;
    public static final int INVALID_ACTIVITY_INSTANCE_ID_MISSING_ACTIVITY = 10221;
    public static final int RECURSIVE_EDIT_LOCK = 10222;
    public static final int LOGIN_FAILURE_LIMIT = 10223;
    public static final int SMS_DIRECTORY_ATTRIBUTE_MISSING = 10224;
    public static final int INVALID_SWAP_ASAP_PROTOCOL = 10225;
    public static final int ADD_OBSERVER_FAILED = 10226;
    public static final int REMOVE_OBSERVER_FAILED = 10227;
    public static final int PROPERTI_MISSING_IN_PROPERTIES_LIST = 10228;
    public static final int DBACCESSHELPER_INITIALIZATION_FAILED = 10229;

    public static final int ERROR_IFLOW_XSD_DATE = 10230;
    public static final int ERROR_XSD_IFLOW_DATE = 10231;
    public static final int ERROR_IFLOW_XSD_TIMESTAMP = 10232;
    public static final int USER_NOTFOUND_IN_DIRECTORY = 10233;
    public static final int PROCESS_MIGRATION_UNIQUE_ACTIVITY_VIOLATION = 10234;
    public static final int PROCESS_MIGRATION_DELETED_RUNNING_ACTIVITY = 10235;
    public static final int PROCESS_MIGRATION_FAILED = 10236;
    public static final int PROCESS_MIGRATION_FAILED_NOT_RUNNING = 10237;
    public static final int DECRYPT_PASSWD_FAILED = 10238;
    public static final int LOGIN_USING_SAME_SESSION = 10239;
    public static final int RECEIVED_EXTERNAL_SOAP_FAULT = 10240;
    public static final int RECEIVED_SOAP_FAULT = 10241;
    public static final int PLAN_NAME_VER_NOT_FOUND = 10242;
    public static final int SERVER_EXCEED_MAX_UNHANDLE_EVENTS_LIMIT = 10243;
    public static final int SERVER_CONNECTION_RESET = 10244;
    public static final int UNABLE_TO_GET = 10245;
    public static final int LOADING_JDBC_DRIVER_FOR_SQL_JAVAACTION_FAILED = 10246;
    public static final int STOP_SOAP_REQUEST_SOURCEID_IS_NULL = 10247;
    public static final int ERROR_IN_HANDLING_SOAP_LISTENER = 10248;
    public static final int SERVER_INIT_FAILED_NO_SERVER_PWD = 10249;
    public static final int SERVER_INIT_FAILED_NO_SERVER_USERNAME = 10250;
    public static final int TRANSACTION_NOT_ALIVE = 10251;
    public static final int DBLINK_NOT_ALIVE = 10252;
    public static final int UNRECOGNIZED_EVENT_OBJECT = 10253;
    public static final int END_TRANSACTION_FAILED = 10254;
    public static final int ILLEGAL_TRANSACTION_CREATION = 10255;
    public static final int ILLEGAL_TRANSACTION_ACCESS = 10256;
    public static final int JAVAACTIONSET_INVALID_ATTRIBUTEVALUE = 10257;
    public static final int JAVAACTION_INVALID_ATTRIBUTENAMES = 10258;
    public static final int JAVAACTION_DUPLICATE_NAME = 10259;
    public static final int COULDNOT_EDIT_TEMPLATE = 10260;
    public static final int MODEL_API_METHOD_FAILED = 10300;
    public static final int ARROW_DOES_NOT_EXIST = 10301;

    public static final int METHOD_NOT_SUPPORTED = 10350;

    public static final int CREATE_TEMPLATE_FAILED = 10400;
    public static final int CREATE_PROCESS_FAILED = 10401;
    public static final int LOCATE_OBSERVER_FAILED = 10402;
    public static final int AUTHORIZATION_FAILED = 10403;
    public static final int CONDITIONSPLIT_XML_PARSING_FAILED = 10404;
    public static final int EVALUATION_OF_SCRIPT_FAILED = 10405;
    public static final int DELETE_TEMPLATE_FAILED = 10406;
    public static final int DELETE_PROCESS_FAILED = 10407;
    public static final int SERVER_LOGOUT_FAILED = 10408;
    public static final int RETRIEVE_PROCESS_FROM_LCC_FAILED = 10409;
    public static final int RETRIEVE_TEMPLATE_FROM_LCC_FAILED = 10410;
    public static final int RETRIEVE_COMMAND_FILE_FAILED = 10411;
    public static final int READING_COMMAND_FILE_FAILED = 10412;
    public static final int LOADING_SCRIPT_COMMAND_FAILED = 10413;
    public static final int ANDJOIN_INVALID_ATTRIBUTES = 10414;
    public static final int IO_ERROR_WRITING_IOR = 10415;
    public static final int VALIDATE_TEMPLATE_FAILED = 10416;
    public static final int INVALID_TEMPLATE_STATE_CHANGE = 10417;
    public static final int DELETE_TEMPLATE_FAILED_REDELETE = 10418;
    public static final int INVALID_TEMPLATE_OWNER = 10419;
    public static final int ATTACHED_PROCESSES_NOT_CLOSED = 10420;
    public static final int MAPPINGDATA_XML_PARSING_FAILED = 10421;
    public static final int CREATE_TEMPLATE_VERSION_FAILED = 10422;
    public static final int GET_VERSION_HISTORY_FAILED = 10423;
    public static final int GET_VERSION_INFO_FAILED = 10424;
    public static final int WRITE_VERSION_INFO_FAILED = 10425;
    public static final int CLOSE_PROCESS_FAILED = 10426;
    public static final int NO_CLIENT_ID_FOUND = 10427;
    public static final int OPENLIST_PROCESSING_FAILED = 10428;
    public static final int NO_VALID_USERS_FOUND = 10429;
    public static final int DATABASE_UNACCESSIBLE = 10430;
    public static final int UNABLE_TO_CONVERT_DATA_TO_XML = 10431;
    public static final int COULD_NOT_RETRIEVE_PROCESS_TIMER = 10432;
    public static final int COULD_NOT_DELETE_PROCESS_TIMER = 10433;
    public static final int DATABASE_UPDATE_FAILED = 10434;
    public static final int ACCESS_HISTORY_RECORD_FAILED = 10435;
    public static final int UNABLE_TO_CONVERT_DATA_FROM_XML = 10436;
    public static final int COULD_NOT_GET_ACTIVITY_ACTOR = 10437;
    public static final int NO_MATCHING_PAIR_FOR_MAPPING = 10438;
    public static final int COULD_NOT_RETRIEVE_WORKITEM = 10439;
    public static final int COULD_NOT_CANCEL_TIMER_INSTANCE = 10440;
    public static final int COULD_NOT_UPDATE_TIMER_INSTANCE = 10441;
    public static final int COULD_NOT_GET_TIMER_INSTANCE = 10442;
    public static final int COULD_NOT_UNLOCK_PROCESS_DEFINITION = 10443;
    public static final int COULD_NOT_UNLOCK_PROCESS_INSTANCE = 10444;
    public static final int COULD_NOT_ARCHIVE_PROCESSES_BY_DATE = 10445;
    public static final int COULD_NOT_CREATE_TIMER_INSTANCE = 10446;
    public static final int UNABLE_TO_COMPLETE_DELAY_NODE = 10447;
    public static final int COULD_NOT_GET_PROCESS_INSTANCE_DETAILS = 10448;
    public static final int COULD_NOT_LOAD_JAVASCRIPT_EXTENSIONS = 10449;
    public static final int USERAGENT_NOT_FOUND_FOR_CLIENT = 10450;
    public static final int UNABLE_TO_START_DMS_SESSION = 10451;
    public static final int COULD_NOT_ADD_ACTIVITY_TIMER = 10452;
    public static final int COULD_NOT_DELETE_ACTIVITY_TIMER = 10453;
    public static final int COULD_NOT_GET_ACTIVITY_TIMER = 10454;
    public static final int COULD_NOT_GET_WORKITEM_STATE = 10455;
    public static final int COULD_NOT_HANDLE_REQUESTED_EVENTS = 10456;
    public static final int COULD_NOT_ADD_PROCESS_TIMER = 10457;
    public static final int COULD_NOT_MODIFY_PROCESS_TIMER = 10458;
    public static final int FILELIST_INVALID_ATTRIBUTES = 10459;
    public static final int NAME_VALUE_SET_INFO_MISSING = 10460;
    public static final int NAME_VALUE_SET_ALREADY_EXISTS = 10461;
    public static final int JS_OPERATION_FAILED = 10462;
    public static final int ERROR_WHILE_PROCESS_CREATION = 10463;
    public static final int ARROW_SCRIPT_NOT_IMPLEMENTED = 10464;
    public static final int READ_ONLY_UDA = 10465;
    public static final int CHECK_PLAN_LOCK_STATUS_FAILED = 10466;
    public static final int PLAN_NAME_NOT_FOUND_IN_URL = 10467;
    public static final int UNSUPPORTED_OPERATION_ON_DATAITEM = 10468;
    public static final int UNABLE_TO_DELETE_PROCESS_LOCKED = 10469;

    public static final int VOTINGSPEC_XML_PARSING_FAILED = 10470;
    public static final int NO_VOTING_RULES_FOUND = 10471;
    public static final int COULD_NOT_DELETE_ALL_ACTIVITY_TIMERS = 10472;
    public static final int COULD_NOT_DELETE_ALL_PROCESS_TIMERS = 10473;
    public static final int TIMERACTION_NOT_FOUND = 10474;
    public static final int DELETE_ARCHIVED_PLAN_FAILED = 10475;
    public static final int DELETE_ARCHIVED_PROCESS_FAILED = 10476;
    public static final int NO_MATCHING_PAIR_FOR_MAPPING_FROM_SUBPROCESS = 10477;

    public static final int SETPRIORITY_WORKITEM_FAILED = 10499;
    public static final int RESUME_WORKITEM_FAILED = 10500;
    public static final int DECLINE_WORKITEM_FAILED = 10501;
    public static final int MAKE_CHOICE_ON_WORKITEM_FAILED = 10502;
    public static final int REASSIGN_MODE_NONE = 10503;
    public static final int NOT_OWNER_SECURE_MODE = 10504;
    public static final int NOT_OWNER_ADMINISTRATOR_ASSIGNEE = 10505;
    public static final int UNHANDLED_REASSIGN_EVENT = 10506;
    public static final int UNHANDLED_DECLINE_EVENT = 10507;
    public static final int UNHANDLED_ACCEPT_EVENT = 10508;
    public static final int RECOVERING_UNHANDLED_EVENTS = 10509;
    public static final int REASSIGNING_ACTIVITY_FAILED_NOT_ACCEPTED = 10510;
    public static final int COULD_NOT_COMPLETE_SUBPROCESS_ACTIVITY = 10511;
    public static final int ACCESS_WORKITEM_FAILED = 10512;
    public static final int UNABLE_TO_GET_FORMS = 10513;
    public static final int DELETE_WORK_ITEMS_FAILED = 10514;
    public static final int MAKE_CHOICE_ON_WORKITEM_FAILED_WAITING_SUBPROCESS = 10515;
    public static final int INACTIVE_WORK_ITEM = 10516;
    public static final int EXCEPTION_ON_WORK_ITEM = 10517;
    public static final int SPAWN_SUB_PROCESS_FAILED = 10518;
    public static final int ACCEPT_SUB_PROCESS_FAILED = 10519;
    public static final int RELOADING_UNHANDLED_EVENTS = 10520;
    public static final int RETRIEVE_OWNER_LIST_FAILED = 10521;
    public static final int EMPTY_REASSIGN_LIST = 10522;
    public static final int NOT_OWNER_OR_ASSIGNEE = 10523;
    public static final int REASSIGNING_WORKITEM_FAILED = 10524;
    public static final int NO_FURTHER_NOTIFICATIONS_WILL_BE_SENT = 10525;
    public static final int COULD_NOT_ACTIVITE_NOTIFICATION_AGENT = 10526;
    public static final int COULD_NOT_ACTIVATE_PULL_SUPPLIER = 10527;
    public static final int REMOVE_NTFXADAPTER_FAILED = 10528;
    public static final int COULD_NOT_ADD_DUPLICATE_OBSERVER = 10529;
    public static final int CREATE_ARCHIVED_TEMPLATE_FAILED = 10530;
    public static final int RETRIEVE_HISTORY_FAILED = 10531;
    public static final int CREATE_ARCHIVED_PROCESS_FAILED = 10532;
    public static final int RETRIEVE_ARCHIVED_TEMPLATE_FAILED = 10533;
    public static final int RETRIEVE_ARCHIVED_PROCESS_FAILED = 10534;
    public static final int CREATE_TEMPLATE_FROM_XML_FAILED = 10535;
    public static final int UPDATE_TEMPLATE_FAILED = 10536;
    public static final int CONVERT_TEMPLATE_FROM_XML_FAILED = 10537;
    public static final int CONVERT_ARCHIVED_PROCESS_FAILED = 10538;
    public static final int ARCHIVE_PROCESS_FAILED = 10539;
    public static final int INVALID_VALUE_IN_IFLOW_PROPERTIES = 10540;
    public static final int ACCEPTED_WORKITEM = 10541;
    public static final int DECLINED_WORKITEM = 10542;
    public static final int UNABLE_TO_SET_ITERATOR_FOR_OPENLIST = 10543;
    public static final int UNABLE_TO_SET_SCRIPT_EXTENSION = 10544;
    public static final int INVALID_ENACTMENT_EVENT = 10545;
    public static final int UNABLE_TO_GET_ITERATOR_VALUES = 10546;
    public static final int UNABLE_TO_PROCESS_NOTIFICATION_FILTER = 10547;
    public static final int CANNOT_DECLINE_WHILE_WAITING_SUBPROCESS = 10548;
    public static final int CANNOT_EDIT_REASSIGN_WHILE_ACTIVE = 10549;
    public static final int ONLY_ASSIGNEE_CAN_CREATE_SUBPROCESS = 10550;
    public static final int CANNOT_MAKECHOICE_WHILE_NOT_RUNNING = 10551;
    public static final int NO_UDA_SORT_WITH_FIELD_SORT = 10552;
    public static final int UDA_DIFFERENT_FOR_FILTER_AND_SORT = 10553;
    public static final int ONLY_RESUME_VALID_WITH_SUSPENDED = 10554;
    public static final int RESUME_REQUIRES_OWNER_OR_ADMIN = 10555;
    public static final int SUSPEND_REQUIRES_OWNER_OR_ADMIN = 10556;
    public static final int EMPTY_OWNER_LIST_IS_INVALID = 10557;
    public static final int INACTIVE_MEANS_NO_ACCEPT_DECLINE_READ = 10558;
    public static final int MAPPINGDATA_INVALID_ATTRIBUTES = 10559;
    public static final int UNKNOWN_EVENT_CHANNEL = 10560;
    public static final int COULD_NOT_GET_PROCESS_TRANSACTION = 10600;
    public static final int COULD_NOT_SET_PROCESS_OWNER = 10601;
    public static final int COULD_NOT_GET_PROCESS_INITIATORS = 10602;
    public static final int COULD_NOT_GET_PROCESS_ROLE_MEMBERS = 10603;
    public static final int COULD_NOT_SET_ACTIVITY_ASSIGNEES = 10604;
    public static final int COULD_NOT_ACCESS_ACTOR_SCRIPT = 10605;
    public static final int NO_REASSIGN_VOTING_ACTIVITY_NODE = 10606;
    public static final int NO_SUB_PROCESS_VOTING_ACTIVITY_NODE = 10607;
    public static final int PI_FAILED_SQ_REGISTERATION = 10608;
    public static final int INVALID_ACTIVITY_OPERATION = 10609;
    public static final int INVALID_WORKITEM_OPERATION = 10610;
    public static final int FAILED_CHANGE_PD_STATE = 10611;
    public static final int FAILED_PUBLISH_UNPUBLISH_IN_REPOSITORY = 10612;
    public static final int COULD_NOT_COMPLETE_OPERATION = 10613;
    public static final int COULD_NOT_FIND_WORKITEM_FOR_ACTIVITY_AND_USER = 10614;
    public static final int NOT_THE_OWNER = 10615;
    public static final int NOT_MEMBER_OF_ROLE = 10616;
    public static final int READ_WORKITEM = 10617;
    public static final int CANNOT_ACCEPT_WORKITEM = 10618;
    public static final int CANNOT_DECLINE_WORKITEM = 10619;
    public static final int UNHANDLED_READ_EVENT = 10620;
    public static final int SERVER_OP_PASSED_BUT_REPOSITORY_PUBLISH_FAILED = 10621;
    public static final int SERVER_OP_PASSED_BUT_REPOSITORY_UNPUBLISH_FAILED = 10622;
    public static final int SERVER_PUBLISHED_PLAN_DESCRIPTION = 10623;
    public static final int UNABLE_TO_RETRIEVE_ACTIVITIES = 10624;
    public static final int UNABLE_TO_RETRIEVE_PARENT_ACTIVITY = 10625;

    public static final int CREATE_NTFXADAPTER_FAILED = 11000;
    public static final int VOTINGDATA_XML_PARSING_FAILED = 11001;
    public static final int VOTINGDATA_INVALID_ATTRIBUTES = 11002;
    public static final int WORKITEM_ALREADY_ACCEPTED_BY_OTHER_PERSON = 11003;
    public static final int JMS_OPEN_CONNECTION_FAILED = 11004;
    public static final int SERVER_PROPERTY_NOT_AVAILABLE = 11005;
    public static final int UNABLE_TO_DELIVER_EVENTCLASS_MESSAGE = 11006;
    public static final int UNABLE_TO_DELIVER_ENACTMENT_MESSAGE = 11007;
    public static final int SMS_CONNECTOR_FAILED = 11008;
    public static final int VALIDATION_ERRORS_FOUND = 11009;
    public static final int RECORD_NOT_FOUND_IN_CACHE = 11010;
    public static final int UNABLE_TO_DELIVER_NOTIFICATION = 11011;
    public static final int CONDITIONSPLIT_INVALID_ATTRIBUTES = 11012;
    public static final int UNABLE_TO_CACHE_OBJECT = 11013;
    public static final int JMS_CLOSE_CONNECTION_FAILED = 11014;
    public static final int JMS_SEND_MESSAGE_FAILED = 11015;
    public static final int UNABLE_TO_UPDATE_CACHE = 11016;
    public static final int UNABLE_TO_DELETE_CACHED_OBJECT = 11017;
    public static final int UNABLE_TO_DELIVER_ANALYTICS_MESSAGE = 11018;

    public static final int SENDER_OR_RECIPIENT_INVALID = 11100;
    public static final int MESSAGE_CONSTRUCTION_ERROR = 11101;
    public static final int MESSAGE_SOURCE_INVALID = 11102;
    public static final int USER_PROFILE_FOR_EMAIL_ERROR = 11103;
    public static final int INVALID_ACCEPT_DECLINE_VALUE = 11104;
    public static final int MESSAGE_PROCESSING_ERROR = 11105;
    public static final int SEND_MESSAGE_FAILED = 11106;

    public static final int FIND_USERLIST_FAILED = 14300;
    public static final int RETRIEVE_PROPERTY_OF_ALLUSER_FAILED = 14301;

    public static final int UPDATE_LIST_FAILED = 14303;
    public static final int CANNOT_RETRIEVE_USER_PROFILE = 14304;
    public static final int CANNOT_UPDATE_USER_PROFILE = 14305;
    public static final int CANNOT_CREATE_USER_PROFILE = 14306;
    public static final int CANNOT_DELETE_USER_PROFILE = 14307;
    public static final int CANNOT_CHECK_USER_EXISTENCE = 14308;
    public static final int CANNOT_RETRIEVE_GROUPS = 14309;
    public static final int OPERATION_NOT_SUPPORTED = 14310;

    public static final int SIMILAR_INPUT_PARAMS = 14351;
    public static final int CREATE_GROUP_FAILED = 14352;
    public static final int RETRIEVE_GROUP_FAILED = 14353;
    public static final int UPDATE_GROUP_FAILED = 14354;
    public static final int DELETE_GROUP_FAILED = 14355;
    public static final int LOCAL_USER_STORE_NOT_ACTIVE = 14356;
    public static final int CREATE_USER_FAILED = 14357;
    public static final int UPDATE_PASSWORD_FAILED = 14358;
    public static final int DELETE_USER_FAILED = 14359;
    public static final int RETRIEVE_ALL_GROUPS_FAILED = 14360;
    public static final int RETRIEVE_ALL_USERS_FAILED = 14361;
    public static final int COULD_NOT_ADD_GROUP_TO_GROUP = 14362;
    public static final int COULD_NOT_REMOVE_GROUP_FROM_GROUP = 14363;
    public static final int COULD_NOT_ADD_USER_TO_GROUP = 14364;
    public static final int COULD_NOT_REMOVE_USER_FROM_GROUP = 14365;
    public static final int ENCRYPTION_FAILED = 14366;
    public static final int COULD_NOT_DELETE_READONLY_GROUP = 14367;
    public static final int USER_NOT_FOUND_IN_DB = 14368;
    public static final int PASSWORD_DOES_NOT_MATCH = 14369;
    public static final int AT_CHARACTER_NOT_ALLOWED = 14370;
    public static final int GROUP_USERLIST_RETRIEVAL_FAILED = 14371;
    public static final int GROUP_WITH_SAME_NAME_EXIST = 14372;
    public static final int GROUP_NOT_FOUND_IN_CACHE = 14373;
    public static final int CAN_NOT_UPDATE_REMOTE_GROUP = 14374;
    public static final int CAN_NOT_DELETE_REMOTE_GROUP = 14375;
    public static final int USER_WITH_SAME_NAME_EXIST = 14376;
    public static final int USER_NOT_FOUND_IN_LIST = 14377;
    public static final int CAN_NOT_UPDATE_REMOTE_USER = 14378;
    public static final int CAN_NOT_DELETE_REMOTE_USER = 14379;
    public static final int COULD_NOT_DELETE_READONLY_USER = 14380;
    public static final int GROUP_NOT_FOUND_IN_DB = 14381;
    public static final int SPACE_NOT_ALLOWED_IN_NAME_PWD = 14382;
    public static final int CYCLIC_DEPENDENCY_FOUND_IN_MAPPING = 14383;
    public static final int GROUP_TO_GROUP_MAPPING_ALREADY_EXISTS = 14384;
    public static final int USER_TO_GROUP_MAPPING_ALREADY_EXISTS = 14385;
    public static final int INPUT_PARAMETER_INVALID = 14386;
    public static final int RETRIEVE_GROUPS_DETAILS_FAILED = 14387;
    public static final int CACHE_UPDATION_FAILED = 14388;
    public static final int GROUP_NOT_DEFINED_IN_LOCALSTORE = 14389;

    public static final int CHECKOUT_RECORD_NOT_FOUND = 14601;
    public static final int LOCKED_FILE = 14602;
    public static final int FIND_FILE_FAILED = 14604;
    public static final int COPY_FILE_FAILED = 14605;
    public static final int READ_WRITE_FILE_FAILED = 14606;
    public static final int OPEN_INPUT_FILE_FAILED = 14607;
    public static final int UNABLE_TO_LOCK_FILE = 14608;
    public static final int UNABLE_TO_UNLOCK_FILE = 14609;

    public static final int INVALID_PATH = 14610;
    public static final int DUPLICATE_FILE = 14611;
    public static final int UNABLE_TO_UPDATE_LOCKED_FILE_LIST = 14612;
    public static final int UNABLE_TO_CHANGE_PERMISSIONS = 14613;
    public static final int UNABLE_TO_UNLOCK_FILE_BECAUSE_LOCKED_BY_ANOTHOR_USER = 14614;

    public static final int DATABASE_CONNECTION_FAILED = 14700;
    public static final int DATABASE_DEADLOCK_OCCURRED = 14701;
    public static final int DATABASE_BEGIN_TRANSACTION_FAILED = 14702;
    public static final int DATABASE_COMMIT_TRANSACTION_FAILED = 14703;
    public static final int DATABASE_ROLLBACK_FAILED = 14704;
    public static final int DATABASE_ADD_CREATE_FAILED = 14705;
    public static final int DATABASE_SET_UPDATE_FAILED = 14706;
    public static final int DATABASE_DELETE_FAILED = 14707;
    public static final int DATABASE_RETRIEVE_FAILED = 14708;
    public static final int DATABASE_SQL_EXECUTION_FAILED = 14709;
    public static final int DATABASE_SQL_CREATE_STATEMENT_FAILED = 14710;
    public static final int DATABASE_ALLOCATE_ID_RANGE_FAILED = 14711;
    public static final int DATABASE_CACHE_MANAGEMENT_FAILED = 14712;
    public static final int DATABASE_CLOSE_CONNECTION_FAILED = 14713;
    public static final int DATABASE_SQL_PREPARED_STATEMENT_FAILED = 14714;
    public static final int DATABASE_RELEASE_CONNECTION_FAILED = 14715;
    public static final int DATABASE_GET_CONNECTION_FAILED = 14716;
    public static final int DATABASE_SQL_CLOSE_OPERATION_FAILED = 14717;
    public static final int DATABASE_SQL_OPERATOR_NOT_SUPPORTED = 14718;
    public static final int DATABASE_FAILED_TO_UPDATE_PROCESSDEFINITION_DUE_TO_SQID_MISMATCH = 14718;
    public static final int DATABASE_FAILED_TO_UPDATE_PROCESSINSTANCE_DUE_TO_SQID_MISMATCH = 14719;
    public static final int DATABASE_REQUEST_FAILED_DUE_TO_HEAVY_LOAD = 14719;

    // i-Flow Model constants
    public static final int COMPONENT_OR_RESOURCE_MANAGMENT_ERROR = 18000;
    public static final int SET_LOOK_AND_FEEL_FAILED = 18001;
    public static final int DESERIALIZE_FAILED = 18002;
    public static final int TIMER_STATUS_RETRIEVAL_ERROR = 18003;
    public static final int STRING_VALIDATION_FAILED = 18004;
    public static final int FTP_LOGIN_FAILED = 18005;

    public static final int ADD_NODE_FAILED = 18021;
    public static final int ARROW_HAS_PENDING_EVENTS = 18022;
    public static final int REMOVE_ARROW_FAILED = 18023;
    public static final int MODIFY_ARROW_FAILED = 18024;
    public static final int ARROW_FORCE_DELETE = 18025;
    public static final int ADD_DATA_REF_FAILED = 18026;
    public static final int ADD_ARROW_FAILED = 18027;
    public static final int REMOVE_DATA_REF_FAILED = 18028;
    public static final int REMOVE_FORM_FAILED = 18029;

    public static final int ADD_FORM_FAILED = 18036;
    public static final int FONT_MANAGEMENT_ERROR = 18037;
    public static final int CONSTRUCTING_PLAN_FAILED = 18038;
    public static final int DUPLICATE_ARROW_NAME = 18039;
    public static final int MAX_NAME_LENGTH_EXCEEDED = 18040;
    public static final int NAME_CANNOT_BE_MISSING_OR_EMPTY = 18041;
    public static final int MAX_DESCRIPTION_LENGTH_EXCEEDED = 18042;
    public static final int MAX_LENGTH_EXCEEDED = 18043;
    public static final int MAX_PLAN_SIZE_EXCEEDED = 18044;
    public static final int MAX_PROC_SIZE_EXCEEDED = 18045;

    public static final int INVALID_DMS_DIRECTORY_FOR_FORMS = 18052;
    public static final int TEMPLATE_STATE_CHANGED = 18053;
    public static final int NEW_TEMPLATE_VERSION_CREATED = 18054;
    public static final int SET_FORMS_FAILED = 18055;
    public static final int EPILOGUE_SCRIPT_IS_NOT_SUPPORTED = 18056;
    public static final int ROLE_IS_NOT_SUPPORTED = 18057;
    public static final int ROLE_SCRIPT_IS_NOT_SUPPORTED = 18058;
    public static final int PROLOGUE_SCRIPT_IS_NOT_SUPPORTED = 18059;
    public static final int CONDITION_SPEC_IS_NOT_SUPPORTED = 18060;
    public static final int TIMER_IS_NOT_SUPPORTED = 18061;
    public static final int TIMER_IS_DUE_DATE = 18062;
    public static final int CONDITION_EVALUATION_FAILED = 18063;

    public static final int NO_DATA_ITEMS_SELECTED_FOR_FORM = 18064;
    public static final int UNKNOWN_NODE_TYPE = 18065;
    public static final int MODIFY_NODE_FAILED = 18067;
    public static final int MODIFY_DATA_REF_FAILED = 18068;
    public static final int PLAN_START_EDIT_FAILED = 18069;
    public static final int PROCESS_INSTANCE_EDIT_FAILED = 18070;
    public static final int GET_CONDITION_SPEC_FAILED = 18071;
    public static final int SET_CONDITION_SPEC_FAILED = 18072;
    public static final int INVALID_OR_MISSING_FORM_PATH = 18073;
    public static final int ARROW_WITH_SAME_NAME_EXISTS = 18074;
    public static final int PEER_PLAN_DOES_NOT_EXISTS = 18075;
    public static final int UNKNOWN_ARROW_TYPE = 18076;
    public static final int INVALID_SOURCE_TARGET_NODE_PAIR = 18077;
    public static final int INVALID_TARGET_NODE = 18078;
    public static final int INVALID_SOURCE_NODE = 18079;
    public static final int UNKNOWN_DATA_REF_TYPE = 18080;
    public static final int DUPLICATE_DATA_REF = 18081;
    public static final int DUPLICATE_FORM = 18082;
    public static final int MULTIPLE_START_NODE_NOT_ALLOWED = 18083;
    public static final int INVALID_FILTER = 18084;
    public static final int UNKNOWN_ARROW_INSTANCE_TYPE = 18085;
    public static final int UNKNOWN_DATA_TYPE = 18086;
    public static final int CONVERT_FROM_BYTE_ARRAY_FAILED = 18087;
    public static final int CONVERT_TO_BYTE_ARRAY_FAILED = 18088;
    public static final int INVALID_BRANCH_SPEC_VALUE = 18089;
    public static final int INVALID_FILTER_OR_SORT_FIELD = 18090;
    public static final int FORM_DESTINATION_PATH_CONTAINS_SPACE = 18091;
    public static final int EXPAND_GROUPS_IS_NOT_SUPPORTED = 18092;

    public static final int CANCEL_EDIT_FAILED = 18093;
    public static final int COMMIT_EDIT_FAILED = 18094;
    public static final int CANNOT_CREATE_ALREADY_EXISTING_PLAN = 18095;
    public static final int MAPPING_DATA_ITEM_REF_FAILED = 18096;
    public static final int INVALID_DATA_ITEM_VALUE = 18097;
    public static final int DUPLICATE_DATA_ITEM = 18098;
    public static final int PROCESS_IS_NULL = 18099;
    public static final int ERROR_PROCESSING_VOTING_RULES = 18100;
    public static final int GET_FORM_FAILED = 18101;
    public static final int JAVAACTIONSET_NAME_MISSING = 18102;
    public static final int GET_FORMS_FAILED = 18103;
    public static final int RULES_FILE_NAME_MISSING = 18104;
    public static final int GET_NODE_INSTANCE_FAILED = 18105;
    public static final int CHOICE_NOT_FOUND = 18106;
    public static final int SUBPLAN_NAME_NOT_FOUND = 18107;
    public static final int VOTING_NOT_SUPPORTED = 18108;
    public static final int VOTING_RULE_NOT_FOUND = 18109;
    public static final int PROLOGUE_JAVAACTIONSET_IS_NOT_SUPPORTED = 18110;
    public static final int EPILOGUE_JAVAACTIONSET_IS_NOT_SUPPORTED = 18111;
    public static final int GET_ROLE_JAVAACTIONSET_FAILED = 18112;
    public static final int JAVAACTIONSET_ALREADY_EXISTS = 18115;
    public static final int USER_DEFINED_CLASS_ERROR = 18116;
    public static final int FAILED_TO_EXECUTE_JAVAACTIONSET = 18117;
    public static final int INVALID_JAVAACTIONSET_FIELD_NAME = 18118;
    public static final int ERROR_PROCESSING_JAVAACTIONSET = 18119;
    public static final int MATCHING_SUB_PLAN_NOT_FOUND = 18120;
    public static final int SET_SUB_PLANID_FAILED = 18121;
    public static final int GET_SUB_PLANID_FAILED = 18122;
    public static final int REMOVE_DATA_ITEM_MAPPING_ELEMENT_FAILED = 18123;
    public static final int DIRECTION_NOT_VALID = 18124;
    public static final int DATA_ITEM_REF_MAPPING_EXISTS = 18125;
    public static final int ARROW_ALREADY_EXISTS = 18126;
    public static final int JAVAACTION_PAKGSTRUCT_NOT_FOUND = 18127;
    public static final int METHOD_NAME_NOTSPEC = 18128;
    public static final int JAVAACTION_ALREADY_EXISTS = 18129;
    public static final int SET_SUB_PLAN_URI_FAILED = 18130;
    public static final int GET_SUB_PLAN_URI_FAILED = 18131;
    public static final int FAILED_TO_EXECUTE_PROCESSOWNERROLE_JAVAACTIONSET = 18132;
    public static final int FAILED_TO_FIRE_RULE = 18133;
    public static final int RULE_FILE_DOES_NOT_EXIST = 18134;
    public static final int BLAZE_RULES_SERVER_CONFIG_FILE_DOES_NOT_EXIST = 18135;
    public static final int JAVA_ACTION_PARAMETER_ERROR = 18136;
    public static final int UNKNOWN_PARAMETER_DATA_TYPE = 18137;
    public static final int CANT_DETERMINE_PARAMETER_TYPE = 18138;
    public static final int EMPTY_PARAMETER = 18139;
    public static final int UNHANDLED_RETURN_TYPE = 18140;
    public static final int CANNOT_SET_RETURN_UDA_FROM_VOID_JAVAACTION_METHOD = 18141;
    public static final int DATABASE_BUSINESS_ACTION_FAILED = 18142;

    /*
     * Coomented the changes done as per BugId 3133 public static final int
     * EPILOGUE_JAVAACTIONSET_IS_NOT_SUPPORTED_FOR_NODEINSTANCE = 18143; public
     * static final int PROLOGUE_JAVAACTIONSET_IS_NOT_SUPPORTED_FOR_NODEINSTANCE =
     * 18144; public static final int ROLE_IS_NOT_SUPPORTED_FOR_NODEINSTANCE =
     * 18145; public static final int
     * CONDITION_SPEC_IS_NOT_SUPPORTED_FOR_NODEINSTANCE = 18146; public static
     * final int GET_CONDITION_SPEC_FAILED_FOR_NODEINSTANCE = 18147; public
     * static final int ROLE_JAVAACTIONSET_IS_NOT_SUPPORTED_FOR_NODEINSTANCE =
     * 18148;
     */

    public static final int ACTION_EDITOR_SUPPRESSED = 18150;
    public static final int DUPLICATE_FORM_NAME = 18151;

    public static final int SET_DATA_VALUE_FAILED = 18203;
    public static final int CLOSELIST_PROCESSING_ERROR = 18204;
    public static final int GET_DATA_TYPE_FAILED = 18205;
    public static final int LISTENER_PROCESSING_ERROR = 18206;
    public static final int WFSESSION_UNDEFINED = 18207;
    public static final int JAVAACTIONSET_HAS_NO_JAVAACTIONS = 18208;
    public static final int PLAN_PEER_IS_NULL = 18209;
    public static final int POPULATING_DATA_FAILED = 18210;
    public static final int NODE_INSTANCE_UNDEFINED = 18211;
    public static final int ERROR_SETTING_NAME_OR_DESCRIPTION = 18212;
    public static final int GET_ATTACHMENT_FAILED = 18213;
    public static final int ATTACHMENT_ALREADY_EXISTS = 18214;
    public static final int ADD_ATTACHMENT_FAILED = 18215;
    public static final int REMOVE_ATTACHMENT_FAILED = 18216;
    public static final int ATTACHMENT_TITLE_ALREADY_EXISTS = 18217;
    public static final int ADD_NODE_INSTANCE_FAILED = 18218;
    public static final int ADD_ARROW_INSTANCE_FAILED = 18219;
    public static final int REMOVE_ARROW_INSTANCE_FAILED = 18220;
    public static final int REMOVE_NODE_INSTANCE_FAILED = 18221;
    public static final int ARROW_INSTANCE_NOT_FOUND = 18222;
    public static final int GET_DATA_FAILED = 18223;
    public static final int MODIFY_NODE_INSTANCE_FAILED = 18224;
    public static final int MODIFY_ARROW_INSTANCE_FAILED = 18225;
    public static final int INVALID_OR_MISSING_FORM_NAME = 18226;
    public static final int SET_FORM_FAILED = 18227;
    public static final int RESET_NODE_INSTANCE_FAILED = 18228;
    public static final int ACTIVATE_NODE_INSTANCE_FAILED = 18229;
    public static final int DEACTIVATE_ARROW_INSTANCE_FAILED = 18230;
    public static final int GROUP_ALREADY_SELECTED = 18231;
    public static final int NODE_INSTANCE_NOT_FOUND = 18232;
    public static final int GET_PLAN_URI_FAILED = 18233;

    public static final int SUB_PROCESS_NOT_SUPPORTED = 18236;
    public static final int ADD_DATA_ITEM_FAILED = 18237;
    public static final int REMOVE_DATA_ITEM_FAILED = 18238;
    public static final int SET_DATA_ITEMS_FAILED = 18239;
    public static final int UNSUPPORTED_OPERATION_ON_ARCHIVED = 18240;
    public static final int PROCESS_INSTANCE_ENACTMENT_EDIT_FAILED = 18241;
    public static final int REMOTE_SUB_PROCESS_NOT_SUPPORTED = 18242;

    public static final int ARROW_INSTANCE_WITH_SAME_NAME_EXISTS = 18244;

    public static final int FIELD_VALIDATION_ERROR = 18246;
    public static final int MAX_ARROW_POINTS_EXCEEDED = 18247;
    public static final int PLAN_NOT_YET_SAVED = 18248;
    public static final int SUB_PROCESS_NOT_CREATED_YET = 18249;
    public static final int CHAINED_PROCESS_NOT_CREATED_YET = 18250;
    public static final int GET_FACTORY_PROPERTIES_FAILED = 18251;

    public static final int WI_UNDEFINED = 18300;
    public static final int WORK_ITEM_NOT_FOUND = 18301;
    public static final int CREATE_WORK_ITEM_FAILED = 18302;
    public static final int USER_ALREADY_SELECTED = 18303;
    public static final int BRANCHSPEC_NOT_FOUND = 18304;
    public static final int NODE_NOT_FOUND = 18305;
    public static final int ARROW_NOT_FOUND = 18306;
    public static final int DATA_REF_NOT_FOUND = 18307;
    public static final int FORM_NOT_FOUND = 18308;
    public static final int ATTACHMENT_NOT_FOUND = 18309;
    public static final int DUPLICATE_FORM_TITLE = 18310;
    public static final int DATA_NOT_FOUND = 18311;
    public static final int SUB_PLAN_NOT_SET = 18312;
    public static final int PROCESSINSTANCE_NOT_IN_EDIT_MODE = 18313;
    public static final int MODIFY_ATTACHMENT_FAILED = 18314;
    public static final int PROCESS_INSTANCE_COMMIT_EDIT_FAILED = 18315;
    public static final int PROCESS_INSTANCE_CANCEL_ENACTMENT_EDIT_FAILED = 18316;
    public static final int GET_DATAITEMS_FAILED = 18317;
    public static final int ARROW_NODE_IN_SAME_PROCESS = 18318;
    public static final int ARROW_NODE_IN_SAME_PLAN = 18319;
    public static final int PROCESSINSTANCE_IN_EDIT_MODE = 18320;
    public static final int AUTHENTICATION_FAILED_ASAP_SWAP = 18321;
    public static final int AUTHORIZATION_HEADER_NOT_FOUND = 18322;
    public static final int INVALID_USERPASS_IN_AUTH_HEADER = 18323;
    public static final int DEFAULT_ASAP_USERPASS_NOT_FOUND = 18324;
    public static final int INVALID_PROCESS_OPERATION = 18325;
    public static final int NODE_NOT_IN_SAME_PLAN = 18326;

    public static final int NOT_ABLE_TO_DELET_SEARCH = 18330;
    public static final int NOT_ABLE_TO_CREAT_SEARCH = 18331;
    public static final int NOT_ABLE_TO_UPDATE_SEARCH = 18332;
    public static final int NOT_ABLE_TO_GET_SEARCH = 18333;
    public static final int NOT_ABLE_TO_GETALL_SEARCH = 18334;

    public static final int COMMUNICATION_TO_SERVER_FAILED = 18350;
    public static final int CONNECTION_TO_SERVER_FAILED = 18351;
    public static final int PLAN_START_EDIT_FAILED_TEMPLATE = 18352;
    public static final int PLAN_DELETE_FAILED_TEMPLATE_PUBLISHED = 18353;
    public static final int INVALID_FORM_TITLE = 18354;
    public static final int INVALID_OCCASION = 18355;
    public static final int RECURSIVE_ACTIONSET = 18356;
    public static final int INVALID_ERRORACTIONSET = 18357;

    // DMS Adapter constants
    public static final int REQUEST_TO_OVERWRITE_FILE = 18400;
    public static final int CHECK_IN_FILE_FAILED = 18401;
    public static final int CHECK_IN_NEW_FILE_FAILED = 18402;
    public static final int GET_DIRECTORY_LISTING_FAILED = 18403;
    public static final int GET_ROOT_FOLDER_FAILED = 18404;
    public static final int CHECK_OUT_FILE_FAILED = 18405;
    public static final int CHECK_IN_LOCATION_NOT_IN_DMSROOT = 18406;
    public static final int CHECK_IN_LOCATION_MISSING = 18407;
    public static final int UNKNOWN_URL_PROTOCOL = 18408;
    public static final int NO_ENTRY_IS_SELECTED = 18409;
    public static final int INVALID_SOCKET = 18410;
    public static final int NO_ENTRIES_EXIST = 18411;
    public static final int GET_USER_GROUPS_FAILED = 18412;
    public static final int GET_GROUP_USERS_LIST_FAILED = 18413;
    public static final int GET_USER_PROPERTY_LIST_FAILED = 18414;
    public static final int UPDATE_USER_PROPERTY_LIST_FAILED = 18415;
    public static final int CREATE_USER_PROPERTY_LIST_FAILED = 18416;
    public static final int SERVER_FILE_ACCESS_NOT_IN_DMSROOT = 18417;
    public static final int INVALID_INPUT_FILE_NAME = 18418;
    public static final int CREATE_INPUT_STREAM_FAILED = 18419;
    public static final int UNABLE_READ_LOCKEDDOCS_FILE = 18420;
    public static final int INVALID_OR_MISSING_ATTACHMENT_NAME = 18421;
    public static final int CLOSE_FILE_FAILED = 18422;
    public static final int NO_CONNECTION_TO_DMS_ADAPTER = 18423;
    public static final int ENABLE_SECURITY_PRIVILEGE_FAILED = 18424;
    public static final int FORM_MUST_BE_RESET_TO_PREVIOUS = 18425;
    public static final int GET_READ_PATH_FAILED = 18426;
    public static final int GET_WRITE_PATH_FAILED = 18427;
    public static final int UNABLE_TO_VIEW_DOCUMENT = 18428;
    public static final int CREATE_OUTPUT_FILE_FAILED = 18429;
    public static final int CREATE_DIRECTORIES_FAILED = 18430;
    public static final int CLOSE_INPUT_STREAM_FAILED = 18431;
    public static final int WRITE_OBJECT_FAILED = 18432;
    public static final int GET_DOC_PROPERTY_LIST_FAILED = 18433;
    public static final int OPEN_ATTACHMENT_WITH_ASSOCIATION_FAILED = 18434;
    public static final int CLOSE_LOCKEDDOCS_FILE_FAILED = 18435;
    public static final int ERROR_PROCESSING_DOCUMENT_ASSOCIATION = 18436;
    public static final int EMPTY_FOLDER_PATH = 18437;
    public static final int INVALID_FOLDER_NAME = 18438;
    public static final int EXTENSION_HANDLER_NOT_FOUND = 18439;
    public static final int DELETE_FILE_LOCATION_NOT_IN_DMS = 18440;
    public static final int UNKNOWN_FILE_TRANSFER_PROTOCOL = 18441;
    public static final int FILE_NOT_PRESENT = 18442;
    public static final int FOLDER_NOT_PRESENT = 18443;
    public static final int NON_DMS_PATH = 18444;
    public static final int UNIVERSAL_TO_LOCAL_PATH_CONVERSION_FAILED = 18445;
    public static final int INVALID_UNIVERSAL_PATH_NAME = 18446;
    public static final int DMS_NO_IMPL_FOUND = 18447;

    // Timer constants
    public static final int INVALID_TIMER_NAME = 18600;
    public static final int INVALID_TASK_TYPE = 18601;
    public static final int INVALID_TIMER_TYPE = 18602;
    public static final int INVALID_TIMER_OBJECT = 18603;
    public static final int INVALID_TIME_INTERVAL = 18604;
    public static final int INVALID_TIMERACTION_OBJECT = 18605;
    public static final int INVALID_SCRIPT_NAME = 18606;

    public static final int INVALID_ESCALATE_NAME_LIST = 18608;

    public static final int INVALID_EMAIL_ORIGINATOR = 18610;
    public static final int INVALID_EMAIL_RECIPIENT = 18611;
    public static final int INVALID_EMAIL_SUBJECT = 18612;
    public static final int INVALID_EMAIL_BODY = 18613;
    public static final int INVALID_CC_LIST = 18614;
    public static final int INVALID_BCC_LIST = 18615;
    public static final int CREATE_SERVER_OBJECT_FAILED = 18616;
    public static final int REMOVE_TIMER_FAILED = 18617;
    public static final int ADD_TIMER_FAILED = 18618;

    public static final int REORDER_TIMERS_FAILED = 18622;

    public static final int CREATE_ACTIVITY_TIMER_FAILED = 18624;
    public static final int CREATE_PROCESS_TIMER_FAILED = 18625;
    public static final int MODIFY_TIMER_FAILED = 18626;
    public static final int ERROR_PROCESSING_HISTORY_EVENTS = 18627;
    public static final int INVALID_ID = 18628;

    public static final int INVALID_SOURCE_TYPE = 18631;
    public static final int TIMER_IS_CONTAINED = 18632;
    public static final int COMPLETED_WORKITEM_NOOP = 18633;
    public static final int GROUPLEVEL_WORKITEM_NOOP = 18634;

    // i-Flow Session constants
    public static final int PROCESS_INSTANCE_NOW_ACTIVE = 18800;
    public static final int INITIALIZE_FAILED = 18801;
    public static final int NEW_CRITERIA_NO_HITS = 18802;
    public static final int PROCESS_INSTANCE_NOW_INACTIVE = 18803;
    public static final int GET_SERVER_LIST_FAILED = 18804;
    public static final int CREATE_PLAN_FAILED = 18805;
    public static final int PRINTING_IN_PROGRESS = 18806;
    public static final int NOT_LOGGED_IN = 18807;
    public static final int GET_PROCESS_INSTANCE_LIST_FAILED = 18808;
    public static final int PRINTING_CANCELLED_OR_ERROR = 18809;
    public static final int CLOSE_PROCESS_INSTANCE_FAILED = 18810;
    public static final int OPEN_PROCESS_INSTANCE_FAILED = 18811;
    public static final int GET_PROCESS_INSTANCE_FAILED = 18812;
    public static final int GET_WORK_ITEM_LIST_FAILED = 18813;
    public static final int GET_PROCESS_DEFINITION_LIST_FAILED = 18814;
    public static final int GET_PROCESS_DEFINITION_FAILED = 18815;
    public static final int LOGIN_FAILED = 18816;
    public static final int LOAD_IMAGE_ICON_FAILED = 18817;
    public static final int GET_DMS_FAILED = 18818;
    public static final int BIND_TO_SERVER_FAILED = 18819;
    public static final int LOGOUT_FAILED = 18820;
    public static final int SYSTEM_BROWSER_NOT_FOUND = 18821;
    public static final int USER_AGENT_UNDEFINED = 18822;
    public static final int GET_DIRECTORY_FAILED = 18823;
    public static final int CONFIRM_DELETE_TEMPLATE = 18824;
    public static final int DELETE_THIS_SESSION = 18825;
    public static final int CREATE_DIRECTORY_SERVICES_FAILED = 18826;
    public static final int CREATE_WFSESSION_FAILED = 18827;
    public static final int VALIDATE_PLAN_FAILED = 18828;
    public static final int GET_NEXT_BATCH_FAILED = 18829;
    public static final int GET_PREVIOUS_BATCH_FAILED = 18830;
    public static final int USER_LOGGED_IN = 18831;
    public static final int ERROR_DURING_SESSION_SHUTDOWN = 18832;
    public static final int MODEL_NOT_INITIALIZED = 18833;
    public static final int DIR_POPULATE_USERS_GROUPS_FAILED = 18834;
    public static final int LOGIN_SUCCESSFUL = 18835;
    public static final int LOGOUT_SUCCESSFUL = 18836;
    public static final int DIR_CHECK_USER_FAILED = 18837;
    public static final int COULD_NOT_ADD_NODE_TO_PD = 18838;
    public static final int COULD_NOT_RECONNECT = 18839;

    // i-Flow DevManager/Admin client messages
    public static final int ERROR_HANDLING_TABLE_VALUE_CHANGED = 19000;
    public static final int CREATE_WFADMINSESSION_FAILED = 19001;
    public static final int NEED_ANOTHER_TEMPLATE_NAME = 19002;
    public static final int ORGANIZER_PANEL_ERROR = 19003;
    public static final int GRAPHICAL_VIEW_MANAGEMENT_ERROR = 19004;
    public static final int INITIALIZATION_ERROR = 19005;
    public static final int ERROR_GETTING_ROLE_MEMBERS = 19006;
    public static final int ROLE_MEMBER_NOT_SELECTED = 19007;
    public static final int USER_PROFILE_DELETED = 19008;
    public static final int DELETE_USER_PROFILE_FAILED = 19009;
    public static final int DELETE_PLAN_FAILED = 19010;
    public static final int PROCESS_SAVED_TO_XML = 19011;
    public static final int GET_ALL_USER_AGENT_INFO_FAILED = 19012;
    public static final int CREATE_USER_PROFILE_FAILED = 19013;
    public static final int GET_USER_PROFILE_FAILED = 19014;
    public static final int UPDATE_USER_PROFILE_FAILED = 19015;
    public static final int REQUEST_TO_SAVE_WITH_NO_CHANGE = 19016;
    public static final int NO_CHANGE_DETECTED = 19017;
    public static final int REQUEST_TO_SAVE_THE_TEMPLATE = 19018;
    public static final int REQUEST_TO_SAVE_THE_PROCESS = 19019;
    public static final int SUBPROCESS_INSTANCE_DOES_NOT_EXIST = 19020;
    // error messages related to custom nodes
    public static final int CANNOT_CREATE_CUSTOM_NODE = 19021;
    public static final int ERROR_READING_CUST_NODE_XML_FILE = 19022;
    public static final int INVALID_CUST_NODE_DEFINITION = 19023;
    public static final int INVALID_CUST_NODE_DEFINITION_BASE_NODE = 19024;
    public static final int DONOT_SEND_SUBPROCESS_CLOSE_EVENT = 19025;
    public static final int CUST_NODE_NOT_CONFIGURED = 19026;
    public static final int NOT_A_VALIDUSER_OR_ADMINUSER = 19027;

    public static final int SET_CHAINED_PLANID_FAILED = 19100;
    public static final int MATCHING_CHAINED_PLAN_NOT_FOUND = 19101;
    public static final int GET_CHAINED_PLANID_FAILED = 19102;
    public static final int CHAINED_PROCESS_NOT_SUPPORTED = 19103;
    public static final int SAVE_CONFIRMATION = 19104;

    public static final int ARCHIVE_PLAN_FAILED = 19200;
    public static final int ARCHIVE_PROCESSINSTANCE_FAILED = 19201;
    public static final int GET_ARCHIVED_XML_PLAN_FAILED = 19202;
    public static final int GET_PROCESSDEF_FROM_ARCHIVE_FAILED = 19203;
    public static final int GET_ARCHIVED_XML_PROCESSINSTANCE_FAILED = 19204;
    public static final int GET_PROCESSINSTANCE_STRUCT_FROM_ARCHIVE_FAILED = 19205;
    public static final int GET_PLAN_FROM_PROCESSDEF_FAILED = 19206;
    public static final int GET_PROCESSINSTANCE_FROM_ARCHIVE_FAILED = 19207;
    public static final int PLAN_CREATED_FROM_XML = 19208;
    public static final int CANNOT_EDIT_ARCHIVED_PROCESSINSTANCE = 19209;
    public static final int PLAN_SAVED_TO_XML = 19210;
    public static final int INVALID_PERCENTAGE_THRESHOLD = 19211;
    public static final int INVALID_NUMBER_THRESHOLD = 19212;
    public static final int INVOKE_DLG_FAILED = 19213;
    public static final int FAILED_SET_INTXN_FLAG = 19214;
    public static final int ARCHIVE_PUBLISHED_PLAN_FAILED = 19215;
    public static final int HELP_FILE_IS_NOT_FOUND = 19216;
    public static final int NO_PROC_PANEL_SELECTED_FOR_FORM = 19217;
    // FTP constants
    public static final int READ_FROM_FTP_PATH_FAILED = 19401;
    public static final int WRITE_LOCAL_SYSTEM_FAILED = 19402;
    public static final int OPEN_PORT_FAILED = 19403;

    public static final int CREATE_SOCKET_FAILED = 19405;
    public static final int CLOSE_SOCKET_FAILED = 19406;
    public static final int WRITE_OUTPUT_STREAM_FAILED = 19407;
    public static final int READ_LINE_FAILED = 19408;
    public static final int GET_LOCAL_HOST_FAILED = 19409;
    public static final int CREATE_OUTPUT_STREAM_FAILED = 19410;

    public static final int WRITE_TO_FTP_PATH_FAILED = 19414;

    // ObjectList constants
    public static final int TOO_MANY_UDA_FILTERS = 19502;

    public static final int UDA_DOES_NOT_EXIST_IN_PROCESS_DEFINITION = 19503;

    public static final int INVALID_UDA_SORT_LIST_FIELD_SORT_SPECIFIED = 19504;

    public static final int TOO_MANY_UDA_SORTS = 19506;
    public static final int FILTER_VALUE_NOT_QUOTED = 19507;
    public static final int INVALID_INPUT_PARAMETER = 19508;
    public static final int BATCH_NOT_OPENED = 19505;
    public static final int FILTER_VALUE_NOT_WITHIN_PARENTHESES = 19509;
    public static final int DISALLOWED_CHARACTER_FOUND = 19510;
    public static final int EMPTY_NULL_NAME_NOT_ALLOWED = 19511;
    public static final int EMPTY_NAME_NOT_ALLOWED = 19512;
    public static final int LIST_CLOSED_OR_NOT_BATCHED = 19513;
    public static final int ESTIMATE_COUNT_FAILED = 19514;

    public static final int INVALID_UDA_IDENTIFIER = 19515;
    public static final int DUPLICATE_UDA = 19516;

    public static final int INVALID_SCOPE_SPECIFIED_FOR_COMMAND = 19600;
    public static final int UDA_VALUE_SPECIFIED_WITHOUT_NAME = 19601;
    public static final int NO_SUPPORTED_COMMAND_SPECIFIED = 19602;
    public static final int INVALID_TAG_NAME_SPECIFIED = 19603;
    public static final int ENCODING_FORMAT_IS_NOT_SUPPORTED = 19604;
    public static final int COULD_NOT_GENERATE_XML_TAG = 19605;
    public static final int USER_DOES_NOT_HAVE_ACCESSIBLE_PLAN = 19606;
    public static final int COULD_NOT_PROCESS_THE_COMMAND = 19607;
    public static final int REQUIRED_PLAN_INFORMATION_MISSING = 19608;
    public static final int REQUIRED_PROCESS_INFORMATION_MISSING = 19609;
    public static final int REQUIRED_WORKITEM_INFORMATION_MISSING = 19610;
    public static final int COULD_NOT_CREATE_DIRECTORY = 19611;
    public static final int GET_USER_FOLDER_FAILED = 19612;
    public static final int COULD_NOT_SEND_EMAIL = 19613;

    // for XPDL support.
    public static final int CREATE_TEMPLATE_FROM_XPDL_FAILED = 19614;
    public static final int CONVERT_TEMPLATE_TO_XPDL_FAILED = 19615;
    public static final int PLAN_SAVED_TO_XPDL = 19616;
    public static final int PLAN_CREATED_FROM_XPDL = 19617;
    public static final int INVALID_FILE_EXTN = 19618;
    public static final int SELECTED_OBJECT_IS_NOT_A_FILE = 19619;

    // for BPEL support.
    public static final int CREATE_TEMPLATE_FROM_BPEL_FAILED = 19620;
    public static final int CONVERT_TEMPLATE_TO_BPEL_FAILED = 19621;
    public static final int PLAN_SAVED_TO_BPEL = 19622;
    public static final int PLAN_CREATED_FROM_BPEL = 19623;
    public static final int ARROW_HAS_NO_ID_ATTRIBUTE = 19624;
    public static final int ARROW_HAS_NO_TO_ATTRIBUTE = 19625;
    public static final int ARROW_HAS_NO_FROM_ATTRIBUTE = 19626;
    public static final int ARROW_HAS_INVALID_SOURCE_ID = 19627;
    public static final int ARROW_HAS_INVALID_TARGET_ID = 19628;
    public static final int PROCDEF_HAS_NO_TRANSITIONS = 19629;

    // Action agent error messages.
    public static final int FAILED_TO_PROCESS_ACTIONAGENT = 19700;
    public static final int FAILED_TO_PARSE_AGENT_CONFIG_FILE = 19701;
    public static final int __IEC_UDA_MISSING_IN_JAVAACTION = 19702;
    public static final int FAILED_TO_CREATE_UPDATE_JAVAACTION = 19703;
    public static final int ACTION_AGENT_CLASS_NOT_SUPPORTED = 19704;
    public static final int COULD_NOT_RETRIEVE_UDA = 19705;
    public static final int INVALID_SERVICE_TYPE = 19706;
    public static final int FAILED_TO_PROCESS_ACTIONAGENT_FOR_WORKITEM = 19707;

    // Rules, Business Calendar, and Service Agent Error messages
    public static final int RULES_PARSER_FAILED = 20001;
    public static final int STRING_LENGTH_ZERO = 20002;
    public static final int COULD_NOT_LOAD_CALENDAR = 20003;
    public static final int COMPUTE_TIMER_TIME_FAILED = 20004;
    public static final int INVALID_CALENDAR = 20005;
    public static final int REACHED_CALENDAR_END = 20006;
    public static final int AGENT_TAVIZ_SERVICE_INITIALIZATION_FAILED = 20007;
    public static final int AGENT_TAVIZ_SERVICE_OPERATION_FAILED = 20008;
    public static final int AGENT_FTP_SERVICE_INITIALIZATION_FAILED = 20009;
    public static final int AGENT_FTP_SERVICE_OPERATION_FAILED = 20010;
    public static final int INVALID_TIME_FOR_TIMER = 20011;
    public static final int SETJAVAACTIONFAILED = 20012;
    public static final int GETJAVAACTIONFAILED = 20013;
    public static final int GET_TIMER_FAILED = 20014;
    public static final int DUPLICATE_UDA_IDENTIFIER = 20015;
    public static final int PLAN_NOT_IN_EDIT_MODE = 20016;
    public static final int FAILED_TO_RETRIEVE_PROCESS_DEFINITION = 20017;
    public static final int PLAN_LOCKED_FOR_EDIT = 20018;
    public static final int ZERO_VALUE_NOT_ALLOWED = 20019;
    public static final int UNRECOGNIZED_BUSINESS_CALENDAR_COMMAND = 20020;
    public static final int NO_BUSINESS_CALENDAR_EXPRESSION = 20021;
    public static final int CALENDER_DURATION_MORE_THAN_TEN_YEARS = 20022;
    public static final int MAX_NUMBER_OF_SHIFTS = 20023;
    public static final int DST_RANGE_EXCEEDS_ALLOWED_RANGE = 20024;
    public static final int SHIFT_RANGE_EXCEEDED = 20025;
    public static final int NEGATIVE_VALUES_NOT_ALLOWED = 20026;

    // i-Flow Analytics Error messages
    public static final int NO_ANALYTICS_SERVER = 21000;
    public static final int RECORD_WORK_TIME_ON_WORKITEM_FAILED = 21001;
    public static final int RECORD_WORK_TIME_EVENT_FAILED = 21002;
    public static final int REQUEST_TO_RECORD_WORK_DURATION = 21003;
    public static final int INVALID_AGGREGATES_VALUE = 21004;
    public static final int ANALYTICS_SERVER_COMMUNICATION_FAILED = 21005;
    public static final int ANALYTICS_SERVER_FAILED = 21006;
    public static final int INVALID_WORK_TIME = 21007;
    public static final int COULD_NOT_SET_COMMIT_INIT_SCRIPT = 21008;
    public static final int DATATYPE_AND_ATTRIBUTES_MISMATCH = 21009;
    public static final int BOOLEAN_CANNOT_BE_DIMENSION = 21010;
    public static final int INVALID_CUBE_NAME = 21011;
    public static final int ANALYTICS_SERVER_COMMUNICATION_SUCCESSFULL = 21012;
    public static final int ANALYTICS_SERVER_FAILED_TO_RESPOND = 21013;
    public static final int ANALYTICS_SERVER_LATEST_EVENT_ID = 21014;
    public static final int ANALYTICS_SERVER_ZERO_EVENT_FOUND = 21015;
    public static final int ANALYTICS_SERVER_EVENT_FOUND = 21016;
    public static final int ANALYTICS_SERVER_ITERATOR_EVENT = 21017;
    public static final int ANALYTICS_SERVER_EVENTS_LODING_COMPLETED = 21018;
    public static final int INVALID_JAVAACTION_NAME = 21019;
    public static final int LODING_PROCDEF_OR_PROCINST_OR_ACTINST_STRUCT_FAILED = 21020;

    // i-Flow error messages for Triggers.
    public static final int INVALID_TRIGGER_TYPE = 21030;
    public static final int TRIGGER_NOT_FOUND = 21031;
    public static final int TRIGGER_ADD_FAILED = 21032;
    public static final int NO_TRIGGERS_DEFINED = 21033;
    public static final int TRIGGER_DELETE_FAILED = 21034;
    public static final int ALL_TRIGGER_DEL_FAILED = 21035;
    public static final int INVALID_TRIGGER_STATE = 21036;
    public static final int TRIGGER_CHANGE_DISALLOWED = 21037;
    public static final int TRIGGER_CHANGE_DISALLOWED_PROCESSES = 21038;
    public static final int INVALID_PARAMETER = 21039;
    public static final int INVALID_PARAMETER_REQUEST = 21040;
    public static final int TRIGGER_EVALUATION_FAILED = 21041;
    public static final int INVALID_TRIGGER_STATE1 = 21042;

    // Trigger Definition in Dev Manager error messages
    public static final int TRIGGER_CONFIG_ERROR_MISSING_JDBC_PARAM = 21050;
    public static final int TRIGGER_CONFIG_ERROR_MISSING_PARAM = 21051;
    public static final int CANNOT_INSTANTIATE_CUST_TRIGGER_TYPE_PANEL = 21052;
    public static final int TRIGGER_JDBC_BROWSING_ERROR = 21053;
    public static final int TRIGGER_JDBC_SCHEMA_TBL_NOT_SELECTED = 21054;
    public static final int TRIGGER_JDBC_OPERATION_NOT_SELECTED = 21055;
    public static final int TRIGGER_ERROR_PARSING_CONDITIONS = 21056;
    public static final int TRIGGER_DATA_MAP_INCOMPLETE = 21057;
    public static final int TRIGGER_ERROR_PARSING_DATAMAP = 21058;
    public static final int MAKE_CHOICE_TRIGGER_NO_CORR_MAP_WARNING = 21059;
    public static final int INVALID_EXPRESSION = 21060;
    public static final int INVALID_HTTP_URL = 21061;
    public static final int HTTP_RESPONSE_CODE = 21062;
    public static final int INVALID_XSD_MIME_TYPE = 21063;
    public static final int TRIG_ERROR_FETCH_XSD = 21064;
    public static final int XML_SCHEMA_REQUIRED = 21065;
    public static final int ERROR_PARSING_XSD = 21066;
    public static final int TRIGGER_JDBC_CONN_FAILED = 21067;
    public static final int ERROR_PARSING_DATASOURCE_XML_CONF = 21068;

    // Start - i-Flow error messages for Action Editors. 21101 - 21200.
    public static final int FIELD_CANNOT_BE_EMPTY = 21101;
    public static final int TARGET_AND_SOURCE_TYPE_MISMATCH = 21102;
    public static final int INVALID_PROCESS_PRIORITY = 21103;
    public static final int PARS_EXCEPTION = 21104;
    public static final int SPECIFIC_UDA_TYPE_REQUIRED = 21105;
    public static final int ACTION_NOT_SUPPORTED = 21106;
    public static final int ESCALATE_JAVAACTION_FAILED = 21107;
    public static final int ACTION_ONLY_SUPPORTED_IN_ROLEJAS = 21108;
    public static final int ACTION_ONLY_SUPPORTED_IN_ACTIVITY_TIMER = 21109;
    public static final int WSDL_NOT_LOADED = 21110;
    // End - i-Flow error messages for Action Editors.

    public static final int GENERATE_SCRIPT_FAILED = 21201;
    public static final int PARSE_SCRIPT_FAILED = 21202;

    // Start - i-Flow error messages for Expression Builder.
    public static final int CAN_NOT_GET_COLUMN_NAME = 21301;
    public static final int COLUMN_PARAM_EDITOR_INIT_FAILED = 21302;
    public static final int EXPR_BUILDER_EVENT_HANDLER_FAILED = 21303;
    public static final int CAN_NOT_CREATE_FUNC_PARAMS_EDITOR = 21304;
    public static final int CAN_NOT_INITIALIZE_EXPR_BUILDER = 21305;
    public static final int JSFUNCTION_EVENT_HANDLER_FAILED = 21306;
    public static final int JSFUNCTION_EDITOR_INIT_FAILED = 21307;
    public static final int CAN_NOT_LAUNCH_EXPR_BUILDER = 21308;
    public static final int SELECT_AN_EXPR_FIELD = 21309;
    public static final int STRING_NOT_WITHIN_DOUBLE_QUOTES = 21310;
    public static final int LAST_CHARACTER_IS_BACKSLASH = 21311;
    // End - i-Flow error messages for Expression Builder.

    // Start - i-Flow error messages for events recovery
    public static final int UNABLE_TO_RECOVER_EVENTS = 21401;
    public static final int NOT_IN_CLUSTERING_ENV = 21402;

    // mozilla Exception
    public static final int JAVA_SCRIPT_EXCEPTION = 21501;

    // SMTP Adapter
    public static final int SMTP_CONNECTION_EXCEPTION = 21601;

    // Due date related error messages
    public static final int DUE_DATES_CANNOT_BE_PERIODIC = 21701;
    public static final int GET_DUE_DATE_FAILED = 21702;

    // Message for InvocationTargetException
    public static final int INVOCATION_TARGET_EXCEPTION = 21801;

    // for Webdav related messages.
    public static final int UNABLE_TO_GET_WEBDAV_RESOURCE = 21901;
    public static final int UNABLE_TO_LIST_DIRECTORY = 21902;
    public static final int UNABLE_TO_DELETE_FILE = 21903;
    public static final int UNABLE_TO_CLOSE_FILE = 21904;
    public static final int UNABLE_TO_PERFORM_OPEN_FOR_READ_OPERATION = 21905;
    public static final int UNABLE_TO_PERFORM_OPEN_FOR_WRITE_OPERATION = 21906;
    public static final int UNABLE_TO_PERFORM_WRITE_OPERATION = 21907;
    public static final int UNABLE_TO_PERFORM_READ_OPERATION = 21908;

    // Message for Workflow Application Packager/Installer
    public static final int CANNOT_SAVE_MANIFEST = 22000;
    public static final int CANNOT_GET_MANIFEST = 22001;
    public static final int CANNOT_INSTALL_PACKAGE = 22002;
    public static final int CANNOT_IMPORT_TEMPLATE_FROM_XPDL = 22003;
    public static final int CANNOT_GET_PACKAGE_DMS_FOLDER = 22004;
    public static final int CANNOT_CREATE_PACKAGE = 22005;
    public static final int CANNOT_GET_MANIFEST_FROM_SERVER = 22006;
    public static final int CANNOT_SAVE_TEMPLATE_INTO_XPDL = 22007;
    public static final int CANNOT_ARCHIVE_PACKAGE = 22008;
    public static final int CANNOT_DEPLOY_PACKAGE = 22009;
    public static final int CANNOT_IMPORT_FILES_TO_PACKAGE = 22010;
    public static final int CANNOT_EXPORT_FILES_FROM_PACKAGE = 22011;
    public static final int CANNOT_RETRIEVE_FILE_FROM_PACKAGE = 22012;
    public static final int CANNOT_UPDATE_FILE_IN_PACKAGE = 22013;
    public static final int GET_PACKAGE_MANIFEST_FAILED = 22014;
    public static final int CHECK_PACKAGE_MANIFEST_FAILED = 22015;
    public static final int PACKAGE_WF_APP_FAILED = 22016;
    public static final int INSTALL_WF_AP_FAILED = 22017;
    public static final int CANNOT_CONVERT_MANIFEST_TO_XML = 22018;
    public static final int CANNOT_CONVERT_MANIFEST_TO_DOM = 22019;
    public static final int CANNOT_CONVERT_XML_TO_MANIFEST = 22020;
    public static final int CANNOT_CONVERT_DOM_TO_MANIFEST = 22021;
    public static final int SET_WF_APP_ENV_MAPPING_FAILED = 22022;
    public static final int GET_WF_APP_SUBPLANS_FAILED = 22023;
    public static final int CANNOT_REWRITE_PATTERN = 22024;
    public static final int CANNOT_IMPORT_FILES_INTO_BPM = 22025;
    public static final int CANNOT_CHECK_FILES_WITH_BPM = 22026;
    public static final int GET_MANIFEST_FAILED = 22027;
    public static final int CHECK_MANIFEST_FAILED = 22028;
    public static final int EXPORT_WF_APP_PACKAGE_FAILED = 22029;
    public static final int IMPORT_WF_APP_PACKAGE_FAILED = 22030;
    public static final int GET_WF_APP_JAVA_CLASS_FAILED = 22031;
    public static final int CANNOT_ADD_FORM_INFO_TO_MANIFEST = 22032;
    public static final int PROBE_FORM_FAILED = 22033;
    public static final int PROBE_ACTION_AGENT_FAILED = 22034;
    public static final int FAILED_TO_GET_ACTION_AGENTS = 22035;
    public static final int LOAD_JAVA_ACTION_FAILED = 22036;
    public static final int CANNOT_ADD_RULE_FILES_INTO_MANIFEST = 22037;
    public static final int PROBE_JAVA_ACTION_FAILED = 22038;
    public static final int CHECK_ACTION_AGENT_FAILED = 22039;
    public static final int IMPORT_ACTION_AGENT_FAILED = 22040;
    public static final int EXPORT_ACTION_AGENT_FAILED = 22041;
    public static final int IMPORT_FORM_FAILED = 22042;
    public static final int EXPORT_FORM_FAILED = 22043;
    public static final int CHECK_FORM_FAILED = 22044;
    public static final int IMPORT_JAVA_ACTION_FAILED = 22045;
    public static final int EXPORT_JAVA_ACTION_FAILED = 22046;
    public static final int CHECK_JAVA_ACTION_FAILED = 22047;
    public static final int CANNOT_EXPORT_FILES_FROM_BPM = 22048;
    public static final int LE_EVENT_NOT_SUPPORTED = 22049;
    public static final int LE_API_NOT_SUPPORTED = 22050;
    public static final int LE_FAILED_TO_GET_LOCK = 22051;
    public static final int FAILED_TO_UPDATE_ACTION_AGENTS = 22052;
    public static final int FAILED_TO_UNLOAD_ACTION_AGENTS = 22053;
    public static final int PLAN_NAME_ALREADY_EXISTS = 22054;
    public static final int NO_ADMIN_AND_NO_APP_OWNER = 22055;
    public static final int APP_NOT_RUNNING = 22056;
    public static final int APPLICATION_DOES_NOT_EXIST = 22057;
    public static final int APPLICATION_NOT_IN_STATE_INITIAL_OR_OFFLINE = 22058;
    public static final int APPLICATION_ALREADY_EXISTS = 22059;
    public static final int APPLICATION_ERROR_WHILE_SYNCHRONIZING = 22060;
    public static final int APPLICATION_OPERATION_ERRORS = 30400;
    public static final int APPLICATION_IN_ERROR_STATE = 30401;
    public static final int APPLICATION_ID_LONGER_THAN_ALLOWED = 30402;
    public static final int APPLICATION_ID_INVALID_CHAR = 30403;
    public static final int APPLICATION_AGENT_NOT_AVAILABLE = 30404;
    public static final int APPLICATION_NOT_IN_STATE_OFFLINE = 30405;
    public static final int DUPLICATE_PLANS = 30406;

    // End - Workflow Application Packager/Installer

    public static final int CANNOT_CLONE_KPI_STRUCT = 22061;
    public static final int CANNOT_CLONE_THRESHOLD_STRUCT = 22062;
    public static final int CANNOT_CLONE_RESPONSE_STRUCT = 22063;

    // Error messages for Dashboard
    public static final int DASH_AVG_TIME_MILIS = 22064;
    public static final int DASH_NOOF_WAITING_PROCACT = 22065;
    public static final int DASH_NOOF_TEMPL_PROC = 22066;
    public static final int DASH_ADD_KPI = 22067;
    public static final int DASH_GET_KPI = 22068;
    public static final int DASH_UPDATE_KPI = 22069;
    public static final int DASH_DELETE_KPI = 22070;
    public static final int DASH_KPI_VALUE = 22071;

    // for the UDDI and Metadata publishing.
    public static final int UNABLE_TO_PUBLISH_METADATA = 22101;
    public static final int UNABLE_TO_UNPUBLISH_METADATA = 22102;
    public static final int UNABLE_TO_PUBLISH_WSDL = 22103;
    public static final int UNABLE_TO_UNPUBLISH_WSDL = 22104;
    public static final int UNABLE_TO_SYNC_WITH_REPOSITORY = 22105;
    public static final int UNABLE_TO_PARSE_WSDL = 22106;
    public static final int UNABLE_TO_FIND_DEFINITION_IN_WSDL = 22107;

    // for the extended attributes
    public static final int FAIL_TO_GET_EXTENDED_ATTRS = 22201;
    public static final int FAIL_TO_SET_EXTENDED_ATTRS = 22202;

    // work item refrsh
    public static final int WORKITEM_REFRESH_ROLE_DOESNOT_MATCH = 22301;
    public static final int WORKITEM_REFRESH_VOTING_NODE = 22302;
    public static final int WORKITEM_REFRESH_FAILED = 22303;
    public static final int WORKITEM_REFRESH_ROLE_IS_EMPTY = 22304;
    public static final int WORKITEM_REFRESH_REASSIGNED_TO_OTHERS = 22305;
    public static final int WORKITEM_REFRESH_WAITING_FOR_SUBPROC = 22306;
    public static final int WORKITEM_REFRESH_WORKITEMS_DELETED = 22307;
    public static final int WORKITEM_REFRESH_WORKITEMS_ADDED = 22308;
    public static final int WORKITEM_REFRESH_WORKITEMS_ADDED_AND_DELETED = 22309;

    // for XPDL
    public static final int WORK_FLOW_TAGES_MISSING = 22401;
    public static final int XPDL_IMPORT_FAILURE = 22402;

    // for Workitem UDA Retrival Optimization.
    public static final int MAX_WI_UDAS_REC_LENGTH_REACHED = 22501;
    public static final int MAX_NO_OF_STRING_DECIMAL_WI_UDAS_REACHED = 22502;
    public static final int MAX_NO_OF_INTEGER_WI_UDAS_REACHED = 22503;
    public static final int MAX_NO_OF_FLOAT_WI_UDAS_REACHED = 22504;
    public static final int UNABLE_TO_CONSTRUCT_WI_UDA_OPTIMIZED_QUERY = 22505;
    public static final int FAILED_TO_REPLACE_WORKLIST_UDA = 22506;
    public static final int STRING_TYPE_WI_UDA_MAX_LENGTH_REACHED = 22507;

    // General Properties
    public static final int API_NOT_IMPLEMENTED_CALL_ON_DEFINITION = 22601;

    // for Configuration Parameters check
    public static final int OLD_CONFIGRATION_FILE_FOUND = 22701;
    public static final int OBSOLETE_PARAMETER_IS_FOUND = 22702;
    public static final int DUPLLICATED_PARAMETER_FOUND = 22703;
    public static final int UNRECOGNIZED_PARAMETER_FOUND = 22704;

    public static final int HTTP_CONN_FAILED_WITH_RESPONSE_CODE = 23000;
    public static final int UDA_TYPE_MISMATCH = 23001;
    public static final int INVALID_INPUT_DATA = 23002;
    public static final int INVALID_OUTPUT_DATA = 23003;
    public static final int FAILED_TO_PARSE_WEBSERVICE_REQUEST_XML = 23004;
    public static final int LOCALE_NOT_SUPPORTED = 23005;
    public static final int FILELISTENER_GETTING_FILE_CONTENT_FAILED = 23006;
    public static final int CLIENTLISTENER_HELPER_IS_NULL = 23007;
    public static final int ADD_URL_TO_CLASSLOADER_FAILED = 23008;
    public static final int VALUE_NOT_FOUND = 23009;
    public static final int DOM_PARSING_FAILED = 23010;
    public static final int CONVERT_STRING_TO_DOC_FAILED = 23011;
    public static final int ROOT_TAG_MISSING = 23012;
    public static final int CONVERT_TO_DATE_FAILED = 23013;
    public static final int MISSING_TAG = 23014;
    public static final int MISSING_PARAMETER = 23015;
    public static final int INVALID_XML_DATA = 23016;
    public static final int ILLEGAL_ARGUMENT = 23017;
    public static final int QUICK_FORM_LOGICAL_FAILURE = 23018;
    public static final int UPLOAD_OF_FILE_DENIED = 23019;
    public static final int MAX_FILE_SIZE_EXCEEDED = 23020;
    public static final int TOTAL_FILE_SIZE_EXCEEDED = 23021;
    public static final int UPLOAD_FAILED = 23022;
    public static final int FILE_DOES_NOT_EXIST_OR_IS_EMPTY = 23023;
    public static final int INDEX_OUT_OF_RANGE = 23024;
    public static final int PHYSICAL_PATH_DENIED = 23025;
    public static final int PATH_IS_NOT_PHYSICAL = 23026;
    public static final int PATH_IS_NOT_VIRTUAL = 23027;
    public static final int FAILED_TO_SAVE_FORM_IN_FILE = 23028;
    public static final int FAILED_TO_SAVE_FILE = 23029;
    public static final int FAILED_TO_CREATE_UDA_MAPPING = 23030;
    public static final int DUE_DATE_IS_NOT_SUPPORTED = 23031;
    public static final int CHECK_URL_AND_SERVER_IS_RUNNING = 23032;
    public static final int USER_AGENT_AND_CLIENT_CONTEXT_OUT_OF_SYNC = 23033;
    public static final int INVALID_UDA_NAME = 23034;
    public static final int FORMS_ARE_NOT_SUPPORTED = 23035;
    public static final int MARK_PROCESS_AS_ERROR_FAILED = 23036;
    public static final int INVALID_UDA = 23037;
    public static final int INVALID_USER_AGENT_SERVICE_PROXY = 23038;
    public static final int INVALID_PLAN_STATE = 23039;
    public static final int INVALID_TRANSPORT_TYPE = 23040;
    public static final int TRANSPORT_TYPE = 23041;
    public static final int INVALID_ATTACHMENT_NAME_OR_PATH = 23042;
    public static final int OPERATING_SYSTEM_NOT_SUPPORTED = 23043;
    public static final int MALFORMED_PASV_REPLY = 23044;
    public static final int INVALID_FTP_REPLY = 23045;
    public static final int INVALID_ACTIVITY_ID = 23046;
    public static final int NOT_PLAN_OWNER = 23047;
    public static final int NO_ASSIGNEES = 23048;
    public static final int INVALID_WORK_ITEM_STATE = 23049;
    public static final int WAITING_FOR_SUB_PROCESS = 23050;
    public static final int UDA_DOES_NOT_EXIST = 23051;
    public static final int UDA_TYPE_MISMATCH_IN_MAPPING = 23052;
    public static final int COULD_NOT_FIND_ELEMENT_NAME_OR_REF_ATTR = 23053;
    public static final int BUFFER_FETCH_ONLY_SUPPORTED_WHEN_NO_BUFFER = 23054;
    public static final int END_OF_LIST_REACHED = 23055;
    public static final int INVALID_OBJECT_IN_LIST = 23056;
    public static final int INVALID_LIST_MODE = 23057;
    public static final int USER_AGENT_CLIENT_CONTEXT_IS_NULL = 23058;
    public static final int STARTUP_FAILED = 23059;
    public static final int CANNOT_UPDATE_CLIENT_HTML_FILES = 23060;
    public static final int CANNOT_CREATE_USER_AGENT = 23061;
    public static final int CANNOT_CREATE_CONNECTOR_USER_AGENT = 23062;
    public static final int CANNOT_CREATE_ADMIN_USER_AGENT = 23063;
    public static final int INVALID_ACTIVITY_STATE = 23064;
    public static final int USER_IS_NOT_AUTHORIZED = 23065;
    public static final int ILLEGAL_EVENT = 23066;
    public static final int INVALID_PROCESS_INSTANCE_STATE = 23067;
    public static final int UNHANDLED_EVENT = 23068;
    public static final int CREATE_FILE_FAILED = 23069;
    public static final int MIN_LENGTH_NOT_REACHED = 23070;
    public static final int COULD_NOT_FIND_SCHEMA_ID = 23071;

    public static final int COULD_NOT_FIND_WSDL_DEFINITION = 23072;
    public static final int COULD_NOT_FIND_BUSINESS_ENTITY = 23073;
    public static final int UNKNOWN_WSDL_TYPE = 23074;

    public static final int TRIAL_VERSION_EXPIRED = 23075;
    public static final int TIMESTAMP_OUT_OF_DATE = 23076;
    public static final int KEY_FILE_IS_EMPTY = 23077;

    public static final int INVALID_ACTIVITY_TYPE = 23078;

    public static final int DUPLICATE_VALUE = 23079;
    public static final int ATTACHMENT_TYPE_NOT_FOUND = 23080;

    public static final int EVENT_EXECUTION_FAILED = 23081;
    public static final int TERMINATE_DELETED_MEMBER_IS_SUBPROC_INDICATOR = 23082;
    public static final int TERMINATE_ROLE_OR_ROLESCRIPT_EMPTY = 23083;
    public static final int FAILED_TO_HANDLE_EVENT = 23082;
    public static final int COULD_NOT_LOAD_RESOURCE_BUNDLE = 23083;
    public static final int COULD_NOT_FIND_RESOURCE_BUNDLE = 23084;

    // for simulation
    public static final int INVALID_NODE_RESOURCE = 23090;
    public static final int SIMULATION_NOT_STARTED = 23091;
    public static final int SIMULATION_STARTED = 23092;
    public static final int SIMULATION_NOT_INITIALIZED = 23093;
    public static final int INVALID_SIMULATION_STATUS = 23094;
    public static final int INVALID_NODE_DURATION = 23095;
    public static final int UNABLE_TO_RENAME_FILE = 23096;
    public static final int SCENARIO_NOT_SPECIFIED = 23097;
    public static final int INVALID_SCENARIO_NAME = 23098;
    public static final int INVALID_XPDL = 23099;
    public static final int INVALID_SIMULATION_TIME_PARAMETER = 23100;
    public static final int ARRIVAL_DEFINITION_NOT_SPECIFIED = 23101;
    public static final int INVALID_ARRIVAL_RATE = 23102;
    public static final int INVALID_ARRIVAL_TYPE = 23103;
    public static final int INVALID_ARROW_PROBABILITY = 23104;
    public static final int INVALID_ARROW_TOTAL_PROBABILITY = 23105;
    public static final int INVALID_ARROW_NAME = 23106;
    public static final int RESOURCE_NOT_SPECIFIED = 23107;
    public static final int INVALID_RESOURCE_TYPE = 23108;
    public static final int INVALID_RESOURCE_NAME = 23109;
    public static final int INVALID_RESOURCE_QUANTITY = 23110;
    public static final int INVALID_RESOURCE_UNIT_COST = 23111;
    public static final int INVALID_RESOURCE_UNIT_OF_MEASURE = 23112;
    public static final int INVALID_HUMAN_RESOURCE = 23113;
    public static final int RESOURCE_MISMATCH = 23114;
    public static final int RESOURCE_INCONSISTENCY = 23115;
    public static final int MAX_PROCESS_NUMBER_EXCEEDED = 23116;
    public static final int ARROW_PROBABILITY_NOT_SPECIFIED = 23117;
    public static final int INSUFFICIENT_AVAILABLE_SIMULATION_MEMORY = 23118;
    public static final int UNSUPPORTED_NODE_TYPE_FOR_SIMULATION = 23119;
    public static final int PROCESS_DEFINITION_NOT_SPECIFIED = 23120;
    public static final int MAX_USER_NUMBER_EXCEEDED = 23121;

    public static final int VALIDATION_INVALID_TIMER_TYPE = 23200;
    public static final int VALIDATION_INVALID_TIMER_DURATION = 23201;
    public static final int COMPARISON_OPERTOR_NOT_SUPPORTED_FOR_TYPE_BOOLEAN = 23202;
    public static final int INVALID_UDA_VALUE_FOR_TYPE = 23203;
    public static final int INVALID_UDA_TYPE = 23204;
    public static final int INVALID_ARROW_TYPE = 23205;

    public static final int VALIDATION_START_NODE_MISSING = 23206;
    public static final int VALIDATION_EXIT_NODE_MISSING = 23207;

    public static final int ARROW_NAME_CANNOT_BE_NULL_OR_EMPTY = 23208;
    public static final int NODE_NAME_CANNOT_BE_NULL_OR_EMPTY = 23209;
    public static final int ROLE_OF_NODE_CANNOT_BE_NULL_OR_EMPTY = 23210;
    public static final int CHAINED_PLAN_NOT_SET_FOR_NODE = 23211;
    public static final int REMOTE_PLAN_NOT_SET_FOR_NODE = 23212;
    public static final int ACTION_AGENT_NOT_SUPPORTED_FOR_VOTING_NODE = 23213;
    public static final int MISSING_ARROW_FOR_NODE = 23214;

    public static final int FAIL_TO_GET_UPPER_LEFT_POINT = 23215;
    public static final int FAIL_TO_SET_UPPER_LEFT_POINT = 23216;
    public static final int UDA_NOT_OF_SPECIFIED_TYPE = 23217;

    public static final int INVALID_LANGUAGE_IN_TOOLBAR_HTML = 23218;

    public static final int ADD_TRIGGER_FAILED = 23300;
    public static final int UDA_NAME_INVALID_EMPTY = 23301;

    public static final int QF_CHARWIDTH_INVALID_VALUE = 23501;
    public static final int QF_MAXCHAR_INVALID_VAlUE = 23502;
    public static final int QF_ROW_INVALID_VAlUE = 23503;
    public static final int QF_COL_INVALID_VAlUE = 23504;
    public static final int QF_INVALID_NAME_VALUE = 23505;
    public static final int QF_EMPTY_LIST = 23506;
    public static final int QF_INVALID_ENTRY = 23507;
    public static final int INVALID_DMS_DIRECTORY_FOR_FORMTEMPLATE = 23508;
    public static final int INVALID_FORM_TITLE_LENGTH = 23509;
    public static final int INVALID_FORM_TEMPLATE_TAGS_MISSING = 23510;
    public static final int FAILED_TO_GENERATE_FORM = 23511;
    public static final int NO_VALUE_DEFINED_FOR_LIST = 23512;
    public static final int LIST_VALUES_CANNOT_BE_EMPTY = 23513;
    public static final int TRIGGER_IS_NOT_SUPPORTED = 23516;
    public static final int NO_DATA_FOUND_FOR_SELECT_QUERY = 23517;

    public static final int QF_UDAS_NOT_FOUND_IN_PROCESS = 23518;
    public static final int QF_CONTROLS_NOT_VALID_FOR_UDAS = 23519;

    // Error messages for JScriptScanner
    public static final int FUNCTION_NOT_FOUND = 23600;
    public static final int INVALID_PARAMETERS_FOR_FUNCTION = 23601;
    public static final int PLAN_DOES_NOT_CONTAIN_UDA = 23602;
    public static final int MULTIPLE_STATEMENTS_NOT_ALLOWED = 23603;
    public static final int LIST_CONTAINS_DUPLICATE_NAME = 23604;
    public static final int INVALID_LIST_NAME_OR_VALUE = 23605;
    public static final int ERROR_SAVING_FILE_DTM = 23606;
    public static final int ACTIVE_DECISION_SET_CANNOT_SAVED_DTM = 23607;
    public static final int ERROR_SAVING_DTM = 23608;
    public static final int ERROR_LOADING_DTM = 23609;
    public static final int ERROR_LOADING_DECISION_TABLE_DTM = 23610;
    public static final int DECISION_TABLE_CANNOT_BE_FOUND = 23611;
    public static final int DECISION_TABLE_IS_NOT_ENABLED = 23612;
    public static final int PARAMETER_NOT_FORMATTED_DTM = 23613;
    public static final int DECISION_TABLE_NOT_AVAILABLE = 23614;
    public static final int DATATYPE_NOT_NUMERIC_DTM = 23615;
    public static final int MANIPULATOR_NOT_VALID_NUMBER_DTM = 23616;
    public static final int DATATYPE_NOT_BOOLEAN_DTM = 23617;
    public static final int DATATYPE_NOT_STRING_DTM = 23618;
    public static final int COULD_NOT_LOAD_SESSSION_PROPERTIES_DTM = 23619;
    public static final int COULD_NOT_LOG_IN_USER_DTM = 23620;
    public static final int HELP_CANNOT_BE_DISPLAYED = 23621;
    public static final int MISSING_UDAS_HEADER = 23622;
    public static final int MISSING_UDAS = 23623;
    public static final int DECISION_TABLE_DOES_NOT_EXIST_HEADER = 23624;
    public static final int DECISION_TABLE_DOES_NOT_EXIST = 23625;

    // ----------------
    // Error messages for server self test
    public static final int INVALID_AGENT_NAME = 30000;
    public static final int INVALID_AGENT_RETRY_INTERVAL = 30001;
    public static final int AGENT_RETRY_INTERVAL_MUST_BE_NUM = 30002;
    public static final int INVALID_AGENT_ESCALATION_INTERVAL = 30003;
    public static final int AGENT_ESCALATION_INTERVAL_MUST_BE_NUM = 30004;
    public static final int AGENT_CLASS_NAME_IS_NOT_SPECIFIED = 30005;
    public static final int INVALID_AGENT_CLASS_PATH = 30006;
    public static final int INVALID_AGENT_CONFIG_FILE = 30007;
    public static final int FAIL_TO_LOAD_AGENT_CLASS = 30008;
    public static final int INVALID_JAVA_ACTION_NAME = 30009;
    public static final int INVALID_JAVA_ACTION_CLASS_NAME = 30010;
    public static final int INVALID_JAVA_ACTION_CLASS_PATH = 30011;
    public static final int INVALID_JAVA_ACTION_METHOD = 30012;
    public static final int UNABLE_TO_LOAD_JAVA_ACTION = 30013;
    public static final int UNABLE_TO_HANDLE_JAVA_ACTION = 30014;
    public static final int INVALID_METHOD_PARAMETER_TYPE = 30015;
    public static final int NOT_ABLE_TO_GET_JMS_COMMAND_PROPS = 30016;
    public static final int JMS_COMMAND_TEST_FAILED = 30017;
    public static final int WRONG_JMS_COMMAND_RESPONSE_RECEIVED = 30018;
    public static final int SOAP_LISTENER_TEST_FAILED = 30019;
    public static final int SOAP_LISTENER_TEST_PLAN_EXISTS = 30020;
    public static final int SOAP_LISTENER_RETURNS_WRONG_PI = 30021;

    public static final int ERROR_OCCURED_WHILE_DATABASE_SCHEMA_CHECK = 30026;
    public static final int UNSUPPORTED_DATABASE = 30027;
    public static final int UNABLE_TO_GET_CONNECTION_PARAMETERS = 30028;
    public static final int REQUIRED_DATABASE_OBJECT_DOESNOT_EXIST = 30029;
    public static final int CONFIGURED_DATABASE_DOESNOT_SUPPORT_UNICODE = 30030;
    public static final int DATABASE_AND_SERVER_VERSION_MISMATCH = 30031;

    public static final int ERROR_OCCURED_WHILE_CONNECTING_TO_SMTP_SERVER = 30032;
    public static final int ERROR_OCCURED_WHILE_CHECKING_WEBSERVICE = 30033;
    public static final int SERVER_HOST_NAME_AND_WEBSERVICE_HOST_NAME_MISMATCH = 30034;

    public static final int CONNECTION_TO_DIRECTORY_FAILED = 30040;
    public static final int REQUIRED_GROUPS_NOT_FOUND = 30041;
    public static final int USER_NOT_FOUND_IN_GROUP = 30042;
    public static final int REQUIRED_ATTRIB_NOT_FOUND = 30043;
    public static final int WRITING_ATTRDATA_FAILED = 30044;
    public static final int DEL_ATTRDATA_FAILED = 30045;
    public static final int DMS_FILECONT_INVALID = 30046;
    public static final int DMS_LOCK_FAILED = 30047;
    public static final int DMS_WRITETOFILE_FAILED = 30048;
    public static final int VERIFYDMS_FILEPATH_FAILED = 30049;
    public static final int REQUIRED_ATTRIB_PROPERTY_MISSING = 30050;

    public static final int SELFTEST_EJB_TEST_FAILED = 30061;
    public static final int SELFTEST_JMS_TEST_FAILED = 30062;
    public static final int SELFTEST_SERVER_NOT_RUNNING = 30063;
    public static final int SELFTEST_TEST_DISABLED = 30064;
    public static final int SELFTEST_FAILED = 30065;
    public static final int SELFTEST_UNSUPPORTED = 30066;
    public static final int SELFTEST_RESOLVE_CLUSTER_SERVER_MAP_FAILED = 30067;
    public static final int SELFTEST_AUTORECOVERY_DISABLED = 30068;
    public static final int SELFTEST_STARTUP_FAILED = 30069;
    public static final int INVALID_URL = 30070;
    public static final int INVALID_SECOND_REQUEST_IN_TX = 30071;

    public static final int TIME_NOT_SPECIFED = 30200;
    public static final int INVALID_START_TIME = 30201;
    public static final int MISSED_EVENT_RETRIEVAL_FAILED = 30202;
    public static final int SET_TIME_RANGE_FAILED = 30203;
    public static final int SET_START_TIME_FAILED = 30204;
    public static final int SET_END_TIME_FAILED = 30205;
    public static final int EVENT_LIST_INIT_FAILED = 30206;

    // Error messages for complex UDA support
    public static final int COMPLEX_UDA_ILLEGAL_DOM = 30302;
    public static final int COMPLEX_UDA_INVALID_XPATH = 30303;
    public static final int COMPLEX_UDA_UNABLE_TO_DETERMINE_DATATYPE = 30304;
    public static final int COMPLEX_UDA_OP_NOT_SUPPORTED_FOR_NON_XML_TYPE = 30305;
    public static final int COMPLEX_UDA_UNABLE_TO_EVALUATE_XPATH = 30306;
    public static final int COMPLEX_UDA_UNABLE_TO_HANDLE_DOM = 30307;
    public static final int COMPLEX_UDA_NODE_NOT_FOUND = 30308;
    public static final int COMPLEX_UDA_UNABLE_TO_CHANGE_NODE_VALUE = 30309;
    public static final int COMPLEX_UDA_INVALID_XML_VALUE = 30310;
    public static final int COMPLEX_UDA_VALIDATION_FAILED = 30311;
    public static final int COMPLEX_UDA_PARENT_NOT_FOUND = 30312;
    public static final int COMPLEX_UDA_INVALID_SCHEMA_VALUE = 30313;
    public static final int COMPLEX_UDA_OP_NOT_SUPPORTED_ON_INSTANCE_LEVEL = 30314;
    public static final int COMPLEX_UDA_CANNOT_REMOVE_CHILD = 30315;
    public static final int COMPLEX_UDA_UNABLE_TO_CREATE_DOC = 30317;
    public static final int COMPLEX_UDA_NODE_IS_NOT_A_TEXT_NODE = 30318;
    public static final int COMPLEX_UDA_NODE_IS_NOT_A_ELEMENT_NODE = 30319;
    public static final int COMPLEX_UDA_UNSUPPORTED_OPERATION_FOR_XML_TYPE = 30320;

    // End of i-Flow Error Message constants

    /***************************************************************************
     * + I-BPM Resource Management
     **************************************************************************/

    private static DebugLog dLog = new DebugLog("ErrorMessage");

    /** Locale instance of this resource mananger (singleton) */
    private static ErrorMessage myInstance;

    /**
     * There are exactly two resource bundles which this class will represent.
     * Some of the methods take a boolean parameter to select between these two
     * bundles. A much cleaner implementation would use two of these classes,
     * with each class representing a different bundle, because then you would
     * not need to pass the boolean into each call to select between the two. A
     * far better approach is to have the GUIException class maintain its own
     * resource bundle, and not call this class at all. But this implementation
     * is hereby forced to be far more complex than it needs to be.
     * 
     * List of resource bundles identified by the locale they belong to. The key
     * of the hashmap is the locale. The value related value is a list (<code>List</code>)
     * of resource bundles that are available for the locale.
     */
    private HashMap ibpmResourceBundles = null;
    private final static String IBPM_RESOURCE_FILE = "ErrorMessage";

    /**
     * Name of the customers resource file. This resource file can be used to
     * announce custom application (=GUI application) specific error codes to
     * the IBPM System. The values of this file are always used when the flag
     * 'useCustomBundle' of the getString methods is called.
     */
    private final static String CUSTOM_RESOURCE_FILE = "GUIErrorMessage";
    private HashMap customResourceBundles = null;

    /**
     * Returns the current instance of this resource manager. Using this method
     * to access the instance ensures that only one instance can exist.
     * 
     * @return The current instance of this resource manager.
     */
    public static synchronized ErrorMessage getInstance() {
        if (myInstance == null) {
            myInstance = new ErrorMessage();
        }
        return myInstance;
    }

    /**
     * Private constructor to guarantee that only one instance of this class can
     * be generated per JVM (singleton).
     * 
     */
    protected ErrorMessage() {
        ibpmResourceBundles = new HashMap();
        customResourceBundles = new HashMap();
    }

    /**
     * Returns the customer resource bundle or the ibpm specifiy bundle for the
     * specified locale. Internally, first it is checked if the bundle was
     * already loaded, if yes the stored one is returned. If the bundle was not
     * loaded until yet, this will be done automatically and added to the
     * internal storage.
     * 
     * @param locale
     *                The locale for which the bundle shall be loaded
     * @param customBundle
     *                <code>true</code> if the custom specifiy bundle shall be
     *                returned; <code>false</code> otherwise.
     * @return The customer specific or ibpm specific resource bundle for the
     *         specified locale.
     */
    private ResourceBundle getResourceBundle(Locale locale, boolean customBundle) {
        ResourceBundle bundle = null;
        if (customBundle) {
            bundle = (ResourceBundle) customResourceBundles.get(locale);

            // the resource bundle for the specified locale was not loaded
            // until yet, therefore load it now and add it to the internal
            // list of bundles.
            if (bundle == null) {
                try {
                    bundle = ResourceBundle.getBundle(CUSTOM_RESOURCE_FILE,
                            locale);
                    customResourceBundles.put(locale, bundle);
                } catch (MissingResourceException mre) {
                    // Do not log anything since the custom resource bundle is
                    // not
                    // mandatory.
                }
            }
        } else {
            bundle = (ResourceBundle) ibpmResourceBundles.get(locale);

            // the resource bundle for the specified locale was not loaded
            // until yet, therefore load it now and add it to the internal
            // list of bundles.
            if (bundle == null) {
                try {
                    bundle = ResourceBundle.getBundle(IBPM_RESOURCE_FILE,
                            locale);
                    ibpmResourceBundles.put(locale, bundle);
                } catch (MissingResourceException mre) {
                    dLog.prn(new Exception("Failed to load resource bundle '"
                            + IBPM_RESOURCE_FILE + "' for locale '" + locale
                            + "'.", mre));
                }
            }
        }
        return bundle;
    }

    /***************************************************************************
     * + Access to the properties and resource information
     **************************************************************************/
    /**
     * Returns the default locale of this system. The default locale is always
     * used when no one is specified or resources are not available for the
     * specified one.
     * 
     * @return Default locale of this system.
     * @deprecated The locale returned by this method is always the default JVM
     *             locale. Therefore directly use <code>Locale.getDefault</code>
     *             instead.
     * @see Locale#getDefault()
     */
    public Locale getDefaultLocale() {
        return Locale.getDefault();
    }

    /*
     * @deprecated use a string property key instead
     */
    public String getString(int propKey) {
        return getString("ibpm" + Integer.toString(propKey), false);
    }

    /**
     * Returns the value of the supplied property key for the default locale.
     * 
     * @param propKey
     *                Name of property to be returned.
     * @return Value of property key in the default locale or <code>null</code>
     *         if the proeprty key was not found.
     */
    public String getString(String propKey) {
        return getString(propKey, false);
    }

    /**
     * Returns the value of the supplied property key for the default locale.
     * 
     * @param propKey
     *                Name of property to be returned.
     * @param useCustomBundle
     *                <code>true</code> if the customer resource bundles shall
     *                be used to get the value; <code>false</code> if the ibpm
     *                standard resource bundle shall be used.
     * @return Value of property key in the default locale or <code>null</code>
     *         if the proeprty key was not found.
     */
    public String getString(String propKey, boolean useCustomBundle) {
        return getString(propKey, Locale.getDefault(), useCustomBundle);
    }

    /**
     * Returns the value of the supplied property key for the specified locale.
     * If the property key was not found in any of the resource bundles for the
     * specified locale, the value is returned for the current default locale.
     * 
     * @param propKey
     *                Name of property to be returned.
     * @param locale
     *                Locale for which the value shall be returned.
     * @return The value of the supplied property key or <code>null</code> if
     *         it was neither found in the resource bundle of the specified
     *         locale nor of the default locale.
     */
    public String getString(String propKey, Locale locale) {
        return getString(propKey, locale, false);
    }

    /**
     * Returns the value of the supplied property key for the specified locale.
     * If the property key was not found in any of the resource bundles for the
     * specified locale, the value is returned for the current default locale.
     * 
     * @param propKey
     *                Name of property to be returned.
     * @param locale
     *                Locale for which the value shall be returned.
     * @param useCustomBundle
     *                <code>true</code> if the customer resource bundles shall
     *                be used to get the value; <code>false</code> if the ibpm
     *                standard resource bundle shall be used.
     * @return The value of the supplied property key or <code>null</code> if
     *         it was neither found in the resource bundle of the specified
     *         locale nor of the default locale.
     */
    public String getString(String propKey, Locale locale,
            boolean useCustomBundle) {
        String propValue = null;

        if (locale == null) {
            locale = Locale.getDefault();
        }

        ResourceBundle resourceBundle = getResourceBundle(locale,
                useCustomBundle);

        if (resourceBundle != null) {
            propValue = getValue(propKey, resourceBundle);
        } else {
            String bundleName = (useCustomBundle) ? CUSTOM_RESOURCE_FILE
                    : IBPM_RESOURCE_FILE;

            // Do not log a model Exception since it might be that the resource
            // bundle that could not be found is the ibpm default resource
            // bundle
            // In that case throwing a ModelException would release an endless
            // loop
            dLog.prn(new Exception("Could not find resource bundle '"
                    + bundleName + "' for locale '" + locale + "'."));
        }
        return propValue;
    }

    /**
     * Returns the value for the supplied property key from the given list of
     * resource bundles. All resource bundles of the list are checked until the
     * property key was found in one of them. If the property key exists in more
     * than one of the resource bundle, always the first occurence is returned.
     * 
     * @param propKey
     *                Name of property to be returned.
     * @param resourceBundles
     *                The resource bundle where to search for the supplied
     *                property key.
     * @return The value of the property or <code>null</code> if the key was
     *         not found in any of the supplied resource bundles.
     */
    private synchronized String getValue(String propKey,
            ResourceBundle resourceBundle) {
        String propValue = null;
        try {
            propValue = resourceBundle.getString(propKey);
        } catch (Exception e) {
        }

        // The above code is swallowing an exception, which is not generally
        // allowed. There should be a comment here explaining why it is
        // appropriate. Returning null is a bad pattern in general.

        return propValue;
    }

    /**
     * Returns a message string when give the numerical index to that message
     * string.
     * 
     * @deprecated Use method <code>getString</code> instead.
     */
    // Question: why is this deprecated? Everything in this
    // class is static, why has this been changed to have non-static
    // methods which force you to get an instance, when there is a
    // single instancy anyway, which is stored in a static variable
    // anyway? This is a step BACKWARDS.
    public static String getErrorString(int errorCode) {
        return ErrorMessage.getInstance().getString(
                "ibpm" + Integer.toString(errorCode), false);
    }

    /**
     * Test if the given errorCode exists in the ResourceBundle
     * 
     * @deprecated Use method {@link #existsValue(String)} instead.
     */
    public static boolean errorCodeExists(int errorCode) {
        return ErrorMessage.getInstance().existsValue(
                "ibpm" + Integer.toString(errorCode));
    }

    /**
     * Returns if a value for the fiven property key exists.
     * 
     * @param propKey
     *                The key of resource file to search for.
     * @return <code>true</code> if a property entry exists with the given
     *         key. <code>false</code>otherwise.
     */
    public boolean existsValue(String propKey) {
        return existsValue(propKey, false);
    }

    /**
     * Returns if a value for the fiven property key exists.
     * 
     * @param propKey
     *                The key of resource file to search for.
     * @param useCustomBundle
     *                <code>true</code> if the property key should be searched
     *                for in the customers resource bundle; <code>false</code>
     *                if the key shall be searched for in the default resource
     *                bundle of IBPM.
     * @return <code>true</code> if a property entry exists with the given
     *         key. <code>false</code>otherwise.
     */
    public boolean existsValue(String propKey, boolean useCustomBundle) {
        return existsValue(propKey, Locale.getDefault(), useCustomBundle);
    }

    /**
     * Returns if a value for the fiven property key exists.
     * 
     * @param propKey
     *                The key of resource file to search for.
     * @param locale
     *                The Locale of resource bundle where to search for the
     *                property key
     * @param useCustomBundle
     *                <code>true</code> if the property key should be searched
     *                for in the customers resource bundle; <code>false</code>
     *                if the key shall be searched for in the default resource
     *                bundle of IBPM.
     * @return <code>true</code> if a property entry exists with the given
     *         key. <code>false</code>otherwise.
     */
    public boolean existsValue(String propKey, Locale locale,
            boolean useCustomBundle) {
        ResourceBundle bundle = getResourceBundle(locale, useCustomBundle);
        return existsValue(propKey, bundle);
    }

    /**
     * Returns if a value for the fiven property key exists.
     * 
     * NOTE: This method should be static NOTE: Why is this synchronized? There
     * is no reason for that. and it is an unnecessary overhead.
     * 
     * @param propKey
     *                The key of resource file to search for.
     * @param resourceBundle
     *                The resource bundle where to search for the given property
     *                key
     * @return <code>true</code> if a property entry exists with the given
     *         key. <code>false</code>otherwise.
     */
    private synchronized boolean existsValue(String propKey,
            ResourceBundle resourceBundle) {

        if (resourceBundle != null) {
            try {
                resourceBundle.getString(propKey);
                return true;
            } catch (MissingResourceException e) {
            }
        }
        return false;
    }

    /***************************************************************************
     * + Exit of the system in case of an error
     **************************************************************************/

    /**
     * errorExit prints a final message, attaches the exception to the message,
     * and for StartAll users, gives them a chance to view the message before
     * shutdown.
     * 
     * HIGHLY QUESTIONABLE! This routine uses "System.Exit" which is a drastic
     * way to shutdown the operation of a server. A better way is to throw an
     * exception that contains a description of the problem, and allow calling
     * to the chance to take care of the problems. This routine was probably
     * created at a time when exception handling was not reliable, so this
     * drastic measure was used to assure that the program stopped running.
     */
    public static void errorExit(String message) {
        dLog.prn(DebugLog.ERR, message);
        shutdown();
    }

    /**
     * HIGHLY QUESTIONABLE! This routine uses "System.Exit" which is a drastic
     * way to shutdown the operation of a server. A better way is to throw an
     * exception that contains a description of the problem, and allow calling
     * to the chance to take care of the problems. This routine was probably
     * created at a time when exception handling was not reliable, so this
     * drastic measure was used to assure that the program stopped running.
     * 
     * Do not use this routine unless you know for certain that an exception
     * will not work, and you have tried to clean up exception handling to make
     * it work.
     */
    public static void errorExit(int errorCode) {
        dLog.prn(DebugLog.ERR, errorCode);
        shutdown();
    }

    /**
     * HIGHLY QUESTIONABLE! This routine uses "System.Exit" which is a drastic
     * way to shutdown the operation of a server. A better way is to throw an
     * exception that contains a description of the problem, and allow calling
     * to the chance to take care of the problems. This routine was probably
     * created at a time when exception handling was not reliable, so this
     * drastic measure was used to assure that the program stopped running.
     * 
     * Do not use this routine unless you know for certain that an exception
     * will not work, and you have tried to clean up exception handling to make
     * it work.
     */
    public static void errorExit(int errorCode, Throwable e) {
        dLog.prn(DebugLog.ERR, errorCode, e);
        shutdown();
    }

    /**
     * HIGHLY QUESTIONABLE! This routine uses "System.Exit" which is a drastic
     * way to shutdown the operation of a server. A better way is to throw an
     * exception that contains a description of the problem, and allow calling
     * to the chance to take care of the problems. This routine was probably
     * created at a time when exception handling was not reliable, so this
     * drastic measure was used to assure that the program stopped running.
     * 
     * Do not use this routine unless you know for certain that an exception
     * will not work, and you have tried to clean up exception handling to make
     * it work.
     */
    public static void errorExit(int errorCode, String variable) {
        dLog.prn(DebugLog.ERR, errorCode, variable);
        shutdown();
    }

    /**
     * HIGHLY QUESTIONABLE! This routine uses "System.Exit" which is a drastic
     * way to shutdown the operation of a server. A better way is to throw an
     * exception that contains a description of the problem, and allow calling
     * to the chance to take care of the problems. This routine was probably
     * created at a time when exception handling was not reliable, so this
     * drastic measure was used to assure that the program stopped running.
     * 
     * Do not use this routine unless you know for certain that an exception
     * will not work, and you have tried to clean up exception handling to make
     * it work.
     */
    public static void errorExit(int errorCode, String variable, Throwable e) {
        dLog.prn(DebugLog.ERR, errorCode, variable, e);
        shutdown();
    }

    /**
     * HIGHLY QUESTIONABLE! This routine uses "System.Exit" which is a drastic
     * way to shutdown the operation of a server. A better way is to throw an
     * exception that contains a description of the problem, and allow calling
     * to the chance to take care of the problems. This routine was probably
     * created at a time when exception handling was not reliable, so this
     * drastic measure was used to assure that the program stopped running.
     * 
     * Do not use this routine unless you know for certain that an exception
     * will not work, and you have tried to clean up exception handling to make
     * it work.
     */
    public static void shutdown() {
        System.out.println("Press any key to exit...");
        try {
            System.in.read();
        } catch (java.io.IOException ioe) {
            // ignore any errors and exit
        }
        System.exit(-1);
    }
}