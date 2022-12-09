/** AI defines */

#define DEFAULT_AI_LAWID "default"

//AI notification defines
///Alert when a new Cyborg is created.
#define AI_NOTIFICATION_NEW_BORG 1
///Alert when a Cyborg selects a model.
#define AI_NOTIFICATION_NEW_MODULE 2
///Alert when a Cyborg changes their name.
#define AI_NOTIFICATION_CYBORG_RENAMED 3
///Alert when an AI disconnects themselves from their shell.
#define AI_NOTIFICATION_AI_SHELL 4
///Alert when a Cyborg gets disconnected from their AI.
#define AI_NOTIFICATION_CYBORG_DISCONNECTED 5

/** Simple Animal BOT defines */

/// Delay between movemements
#define BOT_STEP_DELAY 4
/// Maximum times a bot will retry to step from its position
#define BOT_STEP_MAX_RETRIES 5

/// Default view range for finding targets.
#define DEFAULT_SCAN_RANGE 7

//Bot types
/// Secutritrons (Beepsky)
#define SEC_BOT (1<<0)
/// ED-209s
#define ADVANCED_SEC_BOT (1<<1)
/// MULEbots
#define MULE_BOT (1<<2)
/// Floorbots
#define FLOOR_BOT (1<<3)
/// Cleanbots
#define CLEAN_BOT (1<<4)
/// Medibots
#define MED_BOT (1<<5)
/// Honkbots & ED-Honks
#define HONK_BOT (1<<6)
/// Firebots
#define FIRE_BOT (1<<7)

//Mode defines
/// Idle
#define BOT_IDLE 0
/// Found target, hunting
#define BOT_HUNT 1
/// Start patrol
#define BOT_START_PATROL 2
/// Patrolling
#define BOT_PATROL 3
/// Summoned to a location
#define BOT_SUMMON 4
/// Currently moving
#define BOT_MOVING 5
/// Secbot - At target, preparing to arrest
#define BOT_PREP_ARREST 6
/// Secbot - Arresting target
#define BOT_ARREST 7
/// Cleanbot - Cleaning
#define BOT_CLEANING 8
/// Floorbots - Repairing hull breaches
#define BOT_REPAIRING 9
/// Medibots - Healing people
#define BOT_HEALING	10
/// Responding to a call from the AI
#define BOT_RESPONDING 11
/// MULEbot - Moving to deliver
#define BOT_DELIVER 12
/// MULEbot - Returning to home
#define BOT_GO_HOME	13
/// MULEbot - Blocked
#define BOT_BLOCKED	14
/// MULEbot - Computing navigation
#define BOT_NAV	15
/// MULEbot - Waiting for nav computation
#define BOT_WAIT_FOR_NAV 16
/// MULEbot - No destination beacon found (or no route)
#define BOT_NO_ROUTE 17

//SecBOT defines on arresting
///Whether arrests should be broadcasted over the Security radio
#define SECBOT_DECLARE_ARRESTS (1<<0)
///Will arrest people who lack an ID card
#define SECBOT_CHECK_IDS (1<<1)
///Will check for weapons, taking Weapons access into account
#define SECBOT_CHECK_WEAPONS (1<<2)
///Will check Security record on whether to arrest
#define SECBOT_CHECK_RECORDS (1<<3)
///Whether we will stun & cuff or endlessly stun
#define SECBOT_HANDCUFF_TARGET (1<<4)

/** Misc Robot defines */

//Assembly defines
#define ASSEMBLY_FIRST_STEP 0
#define ASSEMBLY_SECOND_STEP 1
#define ASSEMBLY_THIRD_STEP 2
#define ASSEMBLY_FOURTH_STEP 3
#define ASSEMBLY_FIFTH_STEP 4
