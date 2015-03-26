----------------
namespace enums
----------------
export constant version = "4.9.2"

public include std/io.e
public include std/os.e
public include std/dll.e
public include std/text.e
public include std/math.e
public include std/error.e
public include std/types.e
public include std/search.e
public include std/convert.e
public include std/console.e
public include std/filesys.e
public include std/machine.e
public include std/sequence.e
public include std/serialize.e

public constant LGPL = read_file(canonical_path("~/demos/license.txt"))

---------------------------------------------------------------------------------
-- ListView/TreeView storage types. Use these when creating new 
-- GtkListStores or GtkTreeStores
---------------------------------------------------------------------------------
public enum
    gCHAR = 12, gUCHAR = 16, gINT   = 24, gUINT = 28, 
    gLONG = 32, gULONG = 36, gINT64 = 40, gUINT64 = 44, 
    gDBL = 60, gFLT = 56,
    gSTR   = 64, gPTR = 68, gBOOL= 20 
-- plus gPIX and gCOMBO, which must be defined at run-time 
-- by GtkEngine.e ... don't ask me why!

-- here's a list of GObject types;
public enum type OBJECT by 4
    void = 4,
    GInterface,
    gchar,
    guchar,
    gboolean,
    gint,
    guint,
    glong,
    gulong,
    gint64,
    guint64,
    GEnum,
    GFlags,
    gfloat,
    gdouble,
    gchararray,
    gpointer,
    GBoxed,
    GParam
end type

------------------------------------------------------------------------
-- These are the widget names used to create GTK widgets;
-- GObject MUST be first on the list, and GtkFinal MUST be last!
-- Other than that, order is unimportant, but try to keep 'em in 
-- alphabetical order just to be neat.
------------------------------------------------------------------------
public enum type WIDGET
    GObject,
    GActionGroup,
    GAppInfo,
    GEmblem,
    GEmblemedIcon,
    GFile,
    GFileIcon,
    GIcon,
    GIdle,
    GList,
    GMenu,
    GMenuItem,
    GMenuModel,
    GSList,
    GThemedIcon,
    GTimeout,
    Cairo_t,
    CairoFontOptions,
    CairoContent_t, 
    CairoLinearGradient,
    CairoPattern,
    CairoPattern_t,
    CairoRadialGradient,
    CairoRegion_t,
    CairoImageSurface,
    CairoStatus_t,
    CairoSurface_t,
    CairoSurfaceType_t,
    GdkCairo_t,
    GdkCursor,
    GdkDevice,
    GdkDeviceManager,
    GdkDisplay,
    GdkEvent,
    GdkEventSequence,
    GdkFrameClock,
    GdkFrameTimings,
    GdkGLContext,
    GdkGLProfile,
    GdkKeymap,
    GdkKeyval,
    GdkPixbuf,
    GdkPixbufAnimation,
    GdkPixbufAnimationIter,
    GdkScreen,
    GdkVisual,
    GdkWindow,
    GdkX11Display,
    GdkX11Screen,
    GdkX11Window,
    GtkAboutDialog,
    GtkAccelGroup,
    GtkAccelLabel,
    GtkAccessible,
    GtkActionBar,
    GtkAdjustment,
    GtkAlignment,
    GtkAppChooser,
    GtkAppChooserButton,
    GtkAppChooserDialog,
    GtkAppChooserWidget,
    GtkAppLaunchContext,
    GtkApplication,
    GtkApplicationWindow,
    GtkArrow,
    GtkAspectFrame,
    GtkAssistant,
    GtkBin,
    GtkBindingEntry,
    GtkBindingSet,
    GtkBox,
    GtkBuildable,
    GtkBuilder,
    GtkButton,
    GtkButtonBox,
    GtkCalendar,
    GtkCellArea,
    GtkCellAreaBox,
    GtkCellAreaCell,
    GtkCellAreaContext,
    GtkCellEditable,
    GtkCellLayout,
    GtkCellRenderer,
    GtkCellRendererAccel,
    GtkCellRendererCombo,
    GtkCellRendererPixbuf,
    GtkCellRendererProgress,
    GtkCellRendererSpin,
    GtkCellRendererSpinner,
    GtkCellRendererText,
    GtkCellRendererToggle,
    GtkCellView,
    GtkCheckButton,
    GtkCheckMenuItem,
    GtkClipboard,
    GtkColorButton,
    GtkColorChooser,
    GtkColorChooserDialog,
    GtkColorChooserWidget,
    GtkColorSelection,
    GtkColorSelectionDialog,
    GtkComboBox,
    GtkComboBoxEntry,
    GtkComboBoxText,
    GtkContainer,
    GtkCssProvider,
    GtkCssSection,
    GtkDialog,
    GtkDrawingArea,
    GtkEditable,
    GtkEntry,
    GtkEntryBuffer,
    GtkEntryCompletion,
    GtkEventBox,
    GtkEventController,
    GtkExpander,
    GtkFileChooser,
    GtkFileChooserButton,
    GtkFileChooserDialog,
    GtkFileChooserWidget,
    GtkFileFilter,
    GtkFixed,
    GtkFlowBox,
    GtkFlowBoxChild,
    GtkFontButton,
    GtkFontChooser,
    GtkFontChooserDialog,
    GtkFontChooserWidget,
    GtkFrame,
    GtkGesture,
    GtkGestureSingle,
    GtkGestureDrag,
    GtkGestureLongPress,
    GtkGestureMultiPress,
    GtkGesturePan,
    GtkGestureRotate,
    GtkGestureSwipe,
    GtkGestureZoom,
    GtkGLArea,
    GtkGrid,
    GtkHeaderBar,
    GtkIconInfo,
    GtkIconTheme,
    GtkIconView,
    GtkImage,
	GtkImageMenuItem,
    GtkInfoBar,
    GtkInvisible,
    GtkLabel,
    GtkLayout,
    GtkLevelBar,
    GtkLinkButton,
    GtkListBox,
    GtkListBoxRow,
    GtkListStore,
    GtkLockButton,
    GtkMenu,
    GtkMenuBar,
    GtkMenuButton,
    GtkMenuItem,
    GtkMenuShell,
    GtkMenuToolButton,
    GtkMessageDialog,
    GtkMisc,
    GtkModelButton,
    GtkMountOperation,
    GtkNotebook,
    GtkNumerableIcon,
    GtkOffscreenWindow,
    GtkOrientable,
    GtkOverlay,
    GtkPaperSize,
    GtkPageRange,
    GtkPageSetup,
    GtkPageSetupUnixDialog,
    GtkPaned,
    GtkPlacesSidebar,
    GtkPlug,
    GtkPopover,
    GtkPopoverMenu,
    GtkPrinter,
    GtkPrintContext,
    GtkPrintJob,
    GtkPrintSettings,
    GtkPrintOperation,
    GtkPrintOperationPreview,
    GtkPrintUnixDialog,
    GtkProgressBar,
    GtkRadioButton,
    GtkRadioMenuItem,
    GtkRadioToolButton,
    GtkRange,
    GtkRcStyle,
    GtkRecentChooser,
    GtkRecentChooserDialog,
    GtkRecentChooserMenu,
    GtkRecentChooserWidget,
    GtkRecentFilter,
    GtkRecentInfo,
    GtkRevealer,
    GtkScale,
    GtkScaleButton,
    GtkScrollable,
    GtkScrollbar,
    GtkScrolledWindow,
    GtkSearchBar,
    GtkSearchEntry,
    GtkSelectionData,
    GtkSeparator,
    GtkSeparatorMenuItem,
    GtkSeparatorToolItem,
    GtkSettings,
    GtkSocket,
    GtkSidebar,
    GtkSizeGroup,
    GtkSpinButton,
    GtkSpinner,
    GtkStack,
    GtkStackSwitcher,
    GtkStatusbar,
    GtkStatusIcon,
    GtkStock,
    GtkStockList,
    GtkStyle,
    GtkStyleContext,
    GtkStyleProvider,
    GtkSwitch,
    GtkTargetEntry,
    GtkTargetList,
    GtkTextAttributes,
    GtkTextBuffer,
    GtkTextChildAnchor,
    GtkTextMark,
    GtkTextTag,
    GtkTextTagTable,
    GtkTextView,
    GtkThemedIcon,
    GtkToggleButton,
    GtkToggleToolButton,
    GtkToolbar,
    GtkToolButton,
    GtkToolItem,
    GtkToolItemGroup,
    GtkToolPalette,
    GtkToolShell,
    GtkTooltip,
    GtkTreeDragDest,
    GtkTreeDragSource,
    GtkTreeIter,
    GtkTreeModel,
    GtkTreeModelFilter,
    GtkTreeModelSort,
    GtkTreePath,
    GtkTreeRowReference,
    GtkTreeSelection,
    GtkTreeSortable,
    GtkTreeStore,
    GtkTreeView,
    GtkTreeViewColumn,
    GtkViewport,
    GtkVolumeButton,
    GtkWidget,
    GtkWidgetPath,
    GtkWindow,
    PangoCairoLayout,
    PangoContext,
    PangoFont,
    PangoFontSet,
    PangoFontsetSimple,
    PangoFontDescription,
    PangoFontFace,
    PangoFontFamily,
    PangoFontMap,
    PangoLanguage,
    PangoLayout,
    PangoLayoutIter,
    PangoLayoutLine,
    PangoLayoutRun,
    PangoTabArray,
    GtkFinal
end type

------------------------------------------------------------------------

public enum -- Response codes returned by button presses, etc;
  MB_YES    = -8,
  MB_NO     = -9,
  MB_OK     = -5,
  MB_CANCEL = -6,
  MB_CLOSE  = -7,
  MB_ABORT  = -4,
  MB_NONE   = -1,
  MB_REJECT = -2,
  MB_ACCEPT = -3,
  MB_APPLY  = -10,
  MB_HELP   = -11
  
public enum -- Orientation:
  VERTICAL = 1, HORIZONTAL = 0
  
public enum -- Sort Order:
  UNSORTED = -1, ASCENDING =  1, DESCENDING = 2
  
public enum by 2 -- Cursors:
  GDK_X_CURSOR = 0,
  GDK_ARROW,
  GDK_BASED_ARROW_DOWN, 
  GDK_BASED_ARROW_UP,
  GDK_BOAT,
  GDK_BOGOSITY,
  GDK_BOTTOM_LEFT_CORNER, 
  GDK_BOTTOM_RIGHT_CORNER,
  GDK_BOTTOM_SIDE,
  GDK_BOTTOM_TEE,
  GDK_BOX_SPIRAL,
  GDK_CENTER_PTR,
  GDK_CIRCLE,
  GDK_CLOCK,
  GDK_COFFEE_MUG,
  GDK_CROSS,
  GDK_CROSS_REVERSE,
  GDK_CROSSHAIR,
  GDK_DIAMOND_CROSS,
  GDK_DOT, 
  GDK_DOTBOX,
  GDK_DOUBLE_ARROW,
  GDK_DRAFT_LARGE,
  GDK_DRAFT_SMALL, 
  GDK_DRAPED_BOX,
  GDK_EXCHANGE,
  GDK_FLEUR,
  GDK_GOBBLER,
  GDK_GUMBY,
  GDK_HAND1,
  GDK_HAND2,
  GDK_HEART,
  GDK_ICON,
  GDK_IRON_CROSS,
  GDK_LEFT_PTR,
  GDK_LEFT_SIDE,
  GDK_LEFT_TEE,
  GDK_LEFTBUTTON,
  GDK_LL_ANGLE,
  GDK_LR_ANGLE,
  GDK_MAN,
  GDK_MIDDLEBUTTON,
  GDK_MOUSE,
  GDK_PENCIL,
  GDK_PIRATE,
  GDK_PLUS,
  GDK_QUESTION_ARROW,
  GDK_RIGHT_PTR,
  GDK_RIGHT_SIDE,
  GDK_RIGHT_TEE,
  GDK_RIGHTBUTTON,
  GDK_RTL_LOGO,
  GDK_SAILBOAT,
  GDK_SB_DOWN_ARROW,
  GDK_SB_H_DOUBLE_ARROW,
  GDK_SB_LEFT_ARROW,
  GDK_SB_RIGHT_ARROW,
  GDK_SB_UP_ARROW,
  GDK_SB_V_DOUBLE_ARROW,
  GDK_SHUTTLE,
  GDK_SIZING,
  GDK_SPIDER,
  GDK_SPRAYCAN,
  GDK_STAR,
  GDK_TARGET,
  GDK_TCROSS,
  GDK_TOP_LEFT_ARROW,
  GDK_TOP_LEFT_CORNER,
  GDK_TOP_RIGHT_CORNER,
  GDK_TOP_SIDE,
  GDK_TOP_TEE,
  GDK_TREK,
  GDK_UL_ANGLE,
  GDK_UMBRELLA,
  GDK_UR_ANGLE,
  GDK_WATCH,
  GDK_XTERM,
  GDK_LAST_CURSOR = 153,
  GDK_BLANK_CURSOR = -2,
  GDK_CURSOR_IS_PIXMAP = -1
  
public enum 

  GTK_LICENSE_UNKNOWN = 0,
  GTK_LICENSE_CUSTOM,
  GTK_LICENSE_GPL_2_0,
  GTK_LICENSE_GPL_3_0,
  GTK_LICENSE_LGPL_2_1,
  GTK_LICENSE_LGPL_3_0,
  GTK_LICENSE_BSD,
  GTK_LICENSE_MIT_X11,
  GTK_LICENSE_ARTISTIC,
  
  GTK_ACCEL_VISIBLE = 1,
  GTK_ACCEL_LOCKED  = 2,
  GTK_ACCEL_MASK    = 7,

  GTK_ALIGN_FILL = 0,
  GTK_ALIGN_START,
  GTK_ALIGN_END,
  GTK_ALIGN_CENTER,
  
  GTK_ANCHOR_CENTER = 0,
  GTK_ANCHOR_NORTH,
  GTK_ANCHOR_NORTH_WEST,
  GTK_ANCHOR_NORTH_EAST,
  GTK_ANCHOR_SOUTH,
  GTK_ANCHOR_SOUTH_WEST,
  GTK_ANCHOR_SOUTH_EAST,
  GTK_ANCHOR_WEST,
  GTK_ANCHOR_EAST,
  GTK_ANCHOR_N = 1,
  GTK_ANCHOR_NW,
  GTK_ANCHOR_NE,
  GTK_ANCHOR_S,
  GTK_ANCHOR_SW,
  GTK_ANCHOR_SE,
  GTK_ANCHOR_W,
  GTK_ANCHOR_E,
   
  GTK_APPLICATION_INHIBIT_LOGOUT = 1,
  GTK_APPLICATION_INHIBIT_SWITCH = 2,
  GTK_APPLICATION_INHIBIT_SUSPEND = 4,
  GTK_APPLICATION_INHIBIT_IDLE = 8,
      
  G_APPLICATION_FLAGS_NONE = 0,
  G_APPLICATION_IS_SERVICE,
  G_APPLICATION_IS_LAUNCHER,
  G_APPLICATION_HANDLES_OPEN = 4,
  G_APPLICATION_HANDLES_COMMAND_LINE = 8,
  G_APPLICATION_SEND_ENVIRONMENT = 16,
  G_APPLICATION_NON_UNIQUE = 32,
 
-- arrows are deprecated  
  GTK_ARROWS_BOTH = 0,
  GTK_ARROWS_START,
  GTK_ARROWS_END,

  GTK_ARROW_UP = 0,
  GTK_ARROW_DOWN,
  GTK_ARROW_LEFT,
  GTK_ARROW_RIGHT,
  GTK_ARROW_NONE,

  GTK_ASSISTANT_PAGE_CONTENT = 0,
  GTK_ASSISTANT_PAGE_INTRO,
  GTK_ASSISTANT_PAGE_CONFIRM,
  GTK_ASSISTANT_PAGE_SUMMARY,
  GTK_ASSISTANT_PAGE_PROGRESS,
  GTK_ASSISTANT_PAGE_CUSTOM,
 
  GTK_EXPAND = 1,
  GTK_SHRINK = 2,
  GTK_FILL   = 4,
   
  GTK_BASELINE_POSITION_TOP = 0,
  GTK_BASELINE_POSITION_CENTER,
  GTK_BASELINE_POSITION_BOTTOM,

  GTK_BORDER_STYLE_NONE = 0,
  GTK_BORDER_STYLE_SOLID,
  GTK_BORDER_STYLE_INSET,
  GTK_BORDER_STYLE_OUTSET,
  GTK_BORDER_STYLE_HIDDEN,
  GTK_BORDER_STYLE_DOTTED,
  GTK_BORDER_STYLE_DASHED,
  GTK_BORDER_STYLE_DOUBLE,
  GTK_BORDER_STYLE_GROOVE,
  GTK_BORDER_STYLE_RIDGE,

  GTK_BUTTON_ROLE_NORMAL = 0,
  GTK_BUTTON_ROLE_CHECK,
  GTK_BUTTON_ROLE_RADIO,
  
  GTK_BUTTONS_NONE = 0,
  GTK_BUTTONS_OK,
  GTK_BUTTONS_CLOSE,
  GTK_BUTTONS_CANCEL,
  GTK_BUTTONS_YES_NO,
  GTK_BUTTONS_OK_CANCEL,
  
  GTK_BUTTONBOX_DEFAULT_STYLE = 0,
  GTK_BUTTONBOX_SPREAD,
  GTK_BUTTONBOX_EDGE,
  GTK_BUTTONBOX_START,
  GTK_BUTTONBOX_END,
  GTK_BUTTONBOX_CENTER,
  
  GTK_CALENDAR_SHOW_HEADING = 1,
  GTK_CALENDAR_SHOW_DAY_NAMES = 2,
  GTK_CALENDAR_NO_MONTH_CHANGE = 4,
  GTK_CALENDAR_SHOW_WEEK_NUMBERS = 8,
  GTK_CALENDAR_SHOW_DETAILS = 16,
  
  GTK_CORNER_TOP_LEFT = 0,
  GTK_CORNER_BOTTOM_LEFT,
  GTK_CORNER_TOP_RIGHT,
  GTK_CORNER_BOTTOM_RIGHT,  
  
  GTK_CURVE_TYPE_LINEAR = 0,
  GTK_CURVE_TYPE_SPLINE,    
  GTK_CURVE_TYPE_FREE,
    
  GTK_DELETE_CHARS = 0,
  GTK_DELETE_WORD_ENDS,
  GTK_DELETE_WORDS,
  GTK_DELETE_DISPLAY_LINES,
  GTK_DELETE_DISPLAY_LINE_ENDS,
  GTK_DELETE_PARAGRAPH_ENDS,      
  GTK_DELETE_PARAGRAPHS,          
  GTK_DELETE_WHITESPACE,         

  GTK_DIALOG_NON_MODAL = 0,
  GTK_DIALOG_MODAL  = 1,
  GTK_DIALOG_DESTROY_WITH_PARENT = 2, 
  GTK_DIALOG_NO_SEPARATOR = 4,
  
  GTK_DIR_TAB_FORWARD = 0,
  GTK_DIR_TAB_BACKWARD,
  GTK_DIR_UP,
  GTK_DIR_DOWN,
  GTK_DIR_LEFT,
  GTK_DIR_RIGHT,
  
  GTK_EVENT_SEQUENCE_NONE = 0,
  GTK_EVENT_SEQUENCE_CLAIMED,
  GTK_EVENT_SEQUENCE_DENIED,
  
  GTK_EXPANDER_COLLAPSED = 0,
  GTK_EXPANDER_SEMI_COLLAPSED,
  GTK_EXPANDER_SEMI_EXPANDED,
  GTK_EXPANDER_EXPANDED,

  GTK_FILE_CHOOSER_ACTION_OPEN = 0,
  GTK_FILE_CHOOSER_ACTION_SAVE,
  GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER,
  GTK_FILE_CHOOSER_ACTION_CREATE_FOLDER,
  
  GTK_ICON_SIZE_INVALID = 0,
  GTK_ICON_SIZE_MENU,
  GTK_ICON_SIZE_SMALL_TOOLBAR,
  GTK_ICON_SIZE_LARGE_TOOLBAR,
  GTK_ICON_SIZE_BUTTON,
  GTK_ICON_SIZE_DND,
  GTK_ICON_SIZE_DIALOG,
  
  GTK_ICON_LOOKUP_NO_SVG           =  1,
  GTK_ICON_LOOKUP_FORCE_SVG        =  2,
  GTK_ICON_LOOKUP_USE_BUILTIN      =  4,
  GTK_ICON_LOOKUP_GENERIC_FALLBACK =  8,
  GTK_ICON_LOOKUP_FORCE_SIZE       = 16,

  GTK_IMAGE_EMPTY = 0,
  GTK_IMAGE_PIXBUF,
  GTK_IMAGE_STOCK,
  GTK_IMAGE_ICON_SET,
  GTK_IMAGE_ANIMATION,
  GTK_IMAGE_ICON_NAME,
  GTK_IMAGE_GICON,

  GTK_IM_PREEDIT_NOTHING = 0,
  GTK_IM_PREEDIT_CALLBACK,
  GTK_IM_PREEDIT_NONE,

  GTK_IM_STATUS_NOTHING = 0,
  GTK_IM_STATUS_CALLBACK,
  GTK_IM_STATUS_NONE,  

  GTK_INPUT_HINT_NONE = 0,
  GTK_INPUT_HINT_SPELLCHECK,
  GTK_INPUT_HINT_NO_SPELLCHECK,
  GTK_INPUT_HINT_WORD_COMPLETION = 4,
  GTK_INPUT_HINT_LOWERCASE = 8,
  GTK_INPUT_HINT_UPPERCASE_CHARS = 16,
  GTK_INPUT_HINT_UPPERCASE_WORDS = 32,
  GTK_INPUT_HINT_UPPERCASE_SENTENCES = 64,
  
  GTK_JUSTIFY_LEFT = 0,
  GTK_JUSTIFY_RIGHT,
  GTK_JUSTIFY_CENTER,
  GTK_JUSTIFY_FILL,  

  GTK_LEVEL_BAR_MODE_CONTINUOUS = 0,
  GTK_LEVEL_BAR_MODE_DISCRETE,
  
  GTK_MATCH_ALL = 0,  
  GTK_MATCH_ALL_TAIL,  
  GTK_MATCH_HEAD,      
  GTK_MATCH_TAIL,      
  GTK_MATCH_EXACT,     
  GTK_MATCH_LAST,  

  GTK_PIXELS = 0,
  GTK_INCHES,
  GTK_CENTIMETERS,
    
  GTK_MESSAGE_INFO = 0,
  GTK_MESSAGE_WARNING,
  GTK_MESSAGE_QUESTION,
  GTK_MESSAGE_ERROR,
  GTK_MESSAGE_OTHER,
  
  GTK_ICON_INFO = 0,
  GTK_ICON_WARNING,
  GTK_ICON_QUESTION,
  GTK_ICON_ERROR,
  GTK_ICON_OTHER,
  
  GTK_MOVEMENT_LOGICAL_POSITIONS = 0, 
  GTK_MOVEMENT_VISUAL_POSITIONS,  
  GTK_MOVEMENT_WORDS,             
  GTK_MOVEMENT_DISPLAY_LINES,     
  GTK_MOVEMENT_DISPLAY_LINE_ENDS, 
  GTK_MOVEMENT_PARAGRAPHS,        
  GTK_MOVEMENT_PARAGRAPH_ENDS,    
  GTK_MOVEMENT_PAGES,             
  GTK_MOVEMENT_BUFFER_ENDS,       
  GTK_MOVEMENT_HORIZONTAL_PAGES,  
 
  GTK_ORIENTATION_HORIZONTAL = 0,
  GTK_ORIENTATION_VERTICAL,
 
  GTK_PACK_START = 0,
  GTK_PACK_END,
  
  GTK_PAN_DIRECTION_LEFT = 0,
  GTK_PAN_DIRECTION_RIGHT,
  GTK_PAN_DIRECTION_UP,
  GTK_PAN_DIRECTION_DOWN,
  
  GTK_PATH_PRIO_LOWEST      =  0,
  GTK_PATH_PRIO_GTK         =  4,
  GTK_PATH_PRIO_APPLICATION =  8,
  GTK_PATH_PRIO_THEME       = 10,
  GTK_PATH_PRIO_RC          = 12,
  GTK_PATH_PRIO_HIGHEST     = 15,

  GTK_PATH_WIDGET = 0,
  GTK_PATH_WIDGET_CLASS,
  GTK_PATH_CLASS,
 
  GTK_PHASE_NONE = 0,
  GTK_PHASE_CAPTURE,
  GTK_PHASE_BUBBLE,
  GTK_PHASE_TARGET,
  
  GTK_POLICY_ALWAYS = 0,
  GTK_POLICY_AUTOMATIC,
  GTK_POLICY_NEVER,
  
  GTK_POS_LEFT = 0,
  GTK_POS_RIGHT,
  GTK_POS_TOP,
  GTK_POS_BOTTOM,  
  LEFT = 0, --aliases;
  RIGHT,
  TOP,
  BOTTOM
  
public enum by * 2
  GTK_PRINT_CAPABILITY_PAGE_SET = 0,
  GTK_PRINT_CAPABILITY_COPIES   = 2,
  GTK_PRINT_CAPABILITY_COLLATE,
  GTK_PRINT_CAPABILITY_REVERSE,
  GTK_PRINT_CAPABILITY_SCALE,
  GTK_PRINT_CAPABILITY_GENERATE_PDF,
  GTK_PRINT_CAPABILITY_GENERATE_PS,
  GTK_PRINT_CAPABILITY_PREVIEW,
  GTK_PRINT_CAPABILITY_NUMBER_UP,
  GTK_PRINT_CAPABILITY_NUMBER_UP_LAYOUT,
  
  GTK_REGION_EVEN   = 0,
  GTK_REGION_ODD    = 1,
  GTK_REGION_FIRST,
  GTK_REGION_LAST,
  GTK_REGION_ONLY,
  GTK_REGION_SORTED,
  
  GTK_STATE_FLAG_NORMAL = 0,
  GTK_STATE_FLAG_ACTIVE = 1,
  GTK_STATE_FLAG_PRELIGHT,
  GTK_STATE_FLAG_SELECTED,
  GTK_STATE_FLAG_INSENSITIVE,
  GTK_STATE_FLAG_INCONSISTENT,
  GTK_STATE_FLAG_FOCUSED,
  GTK_STATE_FLAG_BACKDROP,
  GTK_STATE_FLAG_DIR_LTR ,
  GTK_STATE_FLAG_DIR_RTL,
  GTK_STATE_FLAG_LINK,
  GTK_STATE_FLAG_VISITED,
  GTK_STATE_FLAG_CHECKED 
  
public enum  
  GTK_PROGRESS_LEFT_TO_RIGHT = 0,
  GTK_PROGRESS_RIGHT_TO_LEFT,
  GTK_PROGRESS_BOTTOM_TO_TOP,
  GTK_PROGRESS_TOP_TO_BOTTOM,

  GTK_RELIEF_NORMAL = 0,
  GTK_RELIEF_HALF,
  GTK_RELIEF_NONE,
 
  GTK_RESIZE_PARENT = 0,
  GTK_RESIZE_QUEUE, 
  GTK_RESIZE_IMMEDIATE,    
 
  GTK_REVEALER_TRANSITION_TYPE_NONE = 0,
  GTK_REVEALER_TRANSITION_TYPE_CROSSFADE,
  GTK_REVEALER_TRANSITION_TYPE_SLIDE_RIGHT,
  GTK_REVEALER_TRANSITION_TYPE_SLIDE_LEFT,
  GTK_REVEALER_TRANSITION_TYPE_SLIDE_UP,
  GTK_REVEALER_TRANSITION_TYPE_SLIDE_DOWN,
  
  GTK_SCROLL_STEPS = 0,
  GTK_SCROLL_PAGES,
  GTK_SCROLL_ENDS,
  GTK_SCROLL_HORIZONTAL_STEPS,
  GTK_SCROLL_HORIZONTAL_PAGES,
  GTK_SCROLL_HORIZONTAL_ENDS,
 
  GTK_SCROLL_NONE = 0,
  GTK_SCROLL_JUMP,
  GTK_SCROLL_STEP_BACKWARD,
  GTK_SCROLL_STEP_FORWARD,
  GTK_SCROLL_PAGE_BACKWARD,
  GTK_SCROLL_PAGE_FORWARD,
  GTK_SCROLL_STEP_UP,
  GTK_SCROLL_STEP_DOWN,
  GTK_SCROLL_PAGE_UP,
  GTK_SCROLL_PAGE_DOWN,
  GTK_SCROLL_STEP_LEFT,
  GTK_SCROLL_STEP_RIGHT,
  GTK_SCROLL_PAGE_LEFT,
  GTK_SCROLL_PAGE_RIGHT,
  GTK_SCROLL_START,
  GTK_SCROLL_END,

  GTK_SELECTION_NONE = 0,
  GTK_SELECTION_SINGLE,
  GTK_SELECTION_BROWSE,
  GTK_SELECTION_MULTIPLE, 

  GTK_SHADOW_NONE = 0,
  GTK_SHADOW_IN,
  GTK_SHADOW_OUT,
  GTK_SHADOW_ETCHED_IN,
  GTK_SHADOW_ETCHED_OUT,

  GTK_STATE_NORMAL = 0,
  GTK_STATE_ACTIVE,
  GTK_STATE_PRELIGHT,
  GTK_STATE_SELECTED,
  GTK_STATE_INSENSITIVE,
  GTK_STATE_INCONSISTENT,
  GTK_STATE_FOCUSED,
  GTK_STATE_PRESSED = 1,
  GTK_STATE_MOUSEOVER,

  GTK_TEXT_DIR_NONE = 0,
  GTK_TEXT_DIR_LTR,
  GTK_TEXT_DIR_RTL,
  
  GTK_TOOLBAR_ICONS = 0,
  GTK_TOOLBAR_TEXT,
  GTK_TOOLBAR_BOTH,
  GTK_TOOLBAR_BOTH_HORIZ,  

  GTK_TREE_SORTABLE_DEFAULT_SORT_COLUMN_ID = -1,
  GTK_TREE_SORTABLE_UNSORTED_SORT_COLUMN_ID = -2,

  GTK_UPDATE_CONTINUOUS = 0,
  GTK_UPDATE_DISCONTINUOUS,
  GTK_UPDATE_DELAYED,

  GTK_VISIBILITY_NONE = 0,
  GTK_VISIBILITY_PARTIAL,
  GTK_VISIBILITY_FULL,

  GTK_WIN_POS_NONE = 0,
  GTK_WIN_POS_CENTER,
  GTK_WIN_POS_MOUSE,
  GTK_WIN_POS_CENTER_ALWAYS,
  GTK_WIN_POS_CENTER_ON_PARENT,  
  
  GTK_WINDOW_TOPLEVEL = 0,
  GTK_WINDOW_POPUP,

  GTK_SORT_ASCENDING = 1,
  GTK_SORT_DESCENDING,

  GTK_DRAG_RESULT_SUCCESS = 0,
  GTK_DRAG_RESULT_NO_TARGET,
  GTK_DRAG_RESULT_USER_CANCELLED,
  GTK_DRAG_RESULT_TIMEOUT_EXPIRED,
  GTK_DRAG_RESULT_GRAB_BROKEN,
  GTK_DRAG_RESULT_ERROR,

  PANGO_ELLIPSIZE_NONE = 0,
  PANGO_ELLIPSIZE_START,
  PANGO_ELLIPSIZE_MIDDLE,
  PANGO_ELLIPSIZE_END,

  GDK_SOLID = 0,
  GDK_TILED,
  GDK_STIPPLED,
  GDK_OPAQUE_STIPPLED,
  
  GTK_RESPONSE_NONE = -1,
  GTK_RESPONSE_REJECT = -2,
  GTK_RESPONSE_ACCEPT = -3,
  GTK_RESPONSE_DELETE_EVENT = -4,
  GTK_RESPONSE_OK = -5,
  GTK_RESPONSE_CANCEL = -6,
  GTK_RESPONSE_CLOSE = -7,
  GTK_RESPONSE_YES = -8, 
  GTK_RESPONSE_NO = -9,
  GTK_RESPONSE_APPLY = -10,
  GTK_RESPONSE_HELP  = -11,
  
  GTK_TREE_VIEW_COLUMN_GROW_ONLY = 0,
  GTK_TREE_VIEW_COLUMN_AUTOSIZE,
  GTK_TREE_VIEW_COLUMN_FIXED,
  
  GTK_TREE_VIEW_GRID_LINES_NONE = 0,
  GTK_TREE_VIEW_GRID_LINES_HORIZONTAL,
  GTK_TREE_VIEW_GRID_LINES_VERTICAL,
  GTK_TREE_VIEW_GRID_LINES_BOTH,

  GTK_TEXT_WINDOW_PRIVATE = 0,
  GTK_TEXT_WINDOW_WIDGET,
  GTK_TEXT_WINDOW_TEXT,
  GTK_TEXT_WINDOW_LEFT,
  GTK_TEXT_WINDOW_RIGHT,
  GTK_TEXT_WINDOW_TOP,
  GTK_TEXT_WINDOW_BOTTOM,
  
  G_USER_DIRECTORY_DESKTOP = 0,
  G_USER_DIRECTORY_DOCUMENTS,
  G_USER_DIRECTORY_DOWNLOAD,
  G_USER_DIRECTORY_MUSIC,
  G_USER_DIRECTORY_PICTURES,
  G_USER_DIRECTORY_PUBLIC_SHARE,
  G_USER_DIRECTORY_TEMPLATES,
  G_USER_DIRECTORY_VIDEOS,
  G_USER_N_DIRECTORIES,

  GTK_WRAP_NONE = 0,
  GTK_WRAP_CHAR,
  GTK_WRAP_WORD,
  GTK_WRAP_WORD_CHAR,

  GDK_WINDOW_TYPE_HINT_NORMAL = 0,
  GDK_WINDOW_TYPE_HINT_DIALOG,
  GDK_WINDOW_TYPE_HINT_MENU,
  GDK_WINDOW_TYPE_HINT_TOOLBAR,
  GDK_WINDOW_TYPE_HINT_SPLASHSCREEN,
  GDK_WINDOW_TYPE_HINT_UTILITY,
  GDK_WINDOW_TYPE_HINT_DOCK,
  GDK_WINDOW_TYPE_HINT_DESKTOP,
  GDK_WINDOW_TYPE_HINT_DROPDOWN_MENU,
  GDK_WINDOW_TYPE_HINT_POPUP_MENU, 
  GDK_WINDOW_TYPE_HINT_TOOLTIP,
  GDK_WINDOW_TYPE_HINT_NOTIFICATION,
  GDK_WINDOW_TYPE_HINT_COMBO,
  GDK_WINDOW_TYPE_HINT_DND,

  GDK_ACTION_DEFAULT =  0,
  GDK_ACTION_COPY    =  1,
  GDK_ACTION_MOVE    =  2,
  GDK_ACTION_LINK    =  4,
  GDK_ACTION_PRIVATE =  8,
  GDK_ACTION_ASK     = 16,
  
  GTK_CELL_RENDERER_MODE_INERT = 0,
  GTK_CELL_RENDERER_MODE_ACTIVATABLE,
  GTK_CELL_RENDERER_MODE_EDITABLE,

  GTK_CELL_RENDERER_ACCEL_MODE_GTK = 0,
  GTK_CELL_RENDERER_ACCEL_MODE_OTHER,
  
  GTK_DEST_DEFAULT_MOTION     = 1, 
  GTK_DEST_DEFAULT_HIGHLIGHT  = 2,
  GTK_DEST_DEFAULT_DROP       = 4,
  GTK_DEST_DEFAULT_ALL        = 0x07,

  GTK_SIZE_GROUP_NONE = 0,
  GTK_SIZE_GROUP_HORIZONTAL,
  GTK_SIZE_GROUP_VERTICAL,
  GTK_SIZE_GROUP_BOTH
  
public enum
  MOUSE_BUTTON1 =  1,
  MOUSE_BUTTON2,
  MOUSE_BUTTON3
  
public enum 
  PANGO_SCALE = 1000,
  PANGO_STYLE_NORMAL= 0,
  PANGO_STYLE_ITALIC,
  PANGO_STYLE_OBLIQUE,
  
  PANGO_STRETCH_ULTRA_CONDENSED = 0,
  PANGO_STRETCH_EXTRA_CONDENSED,
  PANGO_STRETCH_CONDENSED,
  PANGO_STRETCH_SEMI_CONDENSED,
  PANGO_STRETCH_NORMAL,
  PANGO_STRETCH_SEMI_EXPANDED,
  PANGO_STRETCH_EXPANDED,
  PANGO_STRETCH_EXTRA_EXPANDED,
  PANGO_STRETCH_ULTRA_EXPANDED,
  
  PANGO_VARIANT_NORMAL=1,
  PANGO_VARIANT_SMALL_CAPS,

  PANGO_WEIGHT_THIN         = 100,
  PANGO_WEIGHT_ULTRALIGHT   = 200,
  PANGO_WEIGHT_LIGHT        = 300,
  PANGO_WEIGHT_BOOK         = 380,
  PANGO_WEIGHT_NORMAL       = 400,
  PANGO_WEIGHT_MEDIUM       = 500,
  PANGO_WEIGHT_SEMIBOLD     = 600,
  PANGO_WEIGHT_BOLD         = 700,
  PANGO_WEIGHT_ULTRABOLD    = 800,
  PANGO_WEIGHT_HEAVY        = 900,
  PANGO_WEIGHT_ULTRAHEAVY   = 1000,
  PANGO_UNIT                = 1024

public enum
  GTK_RECENT_SORT_NONE = 0,
  GTK_RECENT_SORT_MRU,
  GTK_RECENT_SORT_LRU,
  GTK_RECENT_SORT_CUSTOM
  
 public enum by * 2 -- GdkModifierTypes
  GDK_SHIFT_MASK = 1,
  GDK_LOCK_MASK,
  GDK_CONTROL_MASK,
  GDK_MOD1_MASK, -- Alt+
  GDK_MOD2_MASK,
  GDK_MOD3_MASK,
  GDK_MOD4_MASK,
  GDK_MOD5_MASK,
  GDK_BUTTON1_MASK,
  GDK_BUTTON2_MASK,
  GDK_BUTTON3_MASK,
  GDK_BUTTON4_MASK,
  GDK_BUTTON5_MASK,
  SHFT = 1, -- 'shorthand' versions of above
  LOCK,
  CTL,
  ALT
  
 public enum -- events
  GDK_NOTHING = -1,
  GDK_DELETE,
  GDK_DESTROY,
  GDK_EXPOSE,
  GDK_MOTION_NOTIFY,
  GDK_BUTTON_PRESS,
  GDK_2BUTTON_PRESS,
  GDK_3BUTTON_PRESS,
  GDK_BUTTON_RELEASE,
  GDK_KEY_PRESS,
  GDK_KEY_RELEASE,
  GDK_ENTER_NOTIFY,
  GDK_LEAVE_NOTIFY,
  GDK_FOCUS_CHANGE,
  GDK_CONFIGURE,
  GDK_MAP,
  GDK_UNMAP
  
public enum -- event masks
  GDK_EXPOSURE_MASK             = 2,
  GDK_POINTER_MOTION_MASK       = 4,
  GDK_POINTER_MOTION_HINT_MASK  = 8,
  GDK_BUTTON_MOTION_MASK        = 16,
  GDK_BUTTON1_MOTION_MASK       = #20,
  GDK_BUTTON2_MOTION_MASK       = #40,
  GDK_BUTTON3_MOTION_MASK       = #80,
  GDK_BUTTON_PRESS_MASK         = #100,
  GDK_BUTTON_RELEASE_MASK       = #200,
  GDK_KEY_PRESS_MASK            = #400,
  GDK_KEY_RELEASE_MASK          = #800,
  GDK_ENTER_NOTIFY_MASK         = #1000,
  GDK_LEAVE_NOTIFY_MASK         = #2000,
  GDK_FOCUS_CHANGE_MASK         = #4000,
  GDK_STRUCTURE_MASK            = #8000,
  GDK_PROPERTY_CHANGE_MASK      = #10000,
  GDK_VISIBILITY_NOTIFY_MASK    = #20000,
  GDK_PROXIMITY_IN_MASK         = #40000,
  GDK_PROXIMITY_OUT_MASK        = #80000,
  GDK_SUBSTRUCTURE_MASK         = #100000,
  GDK_SCROLL_MASK               = #200000,
  GDK_ALL_EVENTS_MASK           = #3FFFFE,
  
  GDK_PROPERTY_NOTIFY   = 16,
  GDK_SELECTION_CLEAR,
  GDK_SELECTION_REQUEST,
  GDK_SELECTION_NOTIFY,
  GDK_PROXIMITY_IN,
  GDK_PROXIMITY_OUT,
  GDK_DRAG_ENTER,
  GDK_DRAG_LEAVE,
  GDK_DRAG_MOTION,
  GDK_DRAG_STATUS,
  GDK_DROP_START,
  GDK_DROP_FINISHED,
  GDK_CLIENT_EVENT,
  GDK_VISIBILITY_NOTIFY,
  GDK_NO_EXPOSE,
  GDK_SCROLL,
  GDK_WINDOW_STATE,
  GDK_SETTING,
  GDK_OWNER_CHANGE,
  GDK_GRAB_BROKEN,
  GDK_DAMAGE,
  
  GDK_FULLSCREEN_ON_CURRENT_MONITOR = 0,
  GDK_FULLSCREEN_ON_ALL_MONITORS,
  
  GTK_PAGE_SET_ALL = 0,
  GTK_PAGE_SET_EVEN,
  GTK_PAGE_SET_ODD,
  
  GTK_PAGE_ORIENTATION_PORTRAIT = 0,
  GTK_PAGE_ORIENTATION_LANDSCAPE,
  GTK_PAGE_ORIENTATION_REVERSE_PORTRAIT,
  GTK_PAGE_ORIENTATION_REVERSE_LANDSCAPE,
  
  GTK_PRINT_OPERATION_ACTION_PRINT_DIALOG = 0,
  GTK_PRINT_OPERATION_ACTION_PRINT,
  GTK_PRINT_OPERATION_ACTION_PREVIEW,
  GTK_PRINT_OPERATION_ACTION_EXPORT,

  GTK_PRINT_OPERATION_RESULT_ERROR = 0,
  GTK_PRINT_OPERATION_RESULT_APPLY,
  GTK_PRINT_OPERATION_RESULT_CANCEL,
  GTK_PRINT_OPERATION_RESULT_IN_PROGRESS,

  GTK_PRINT_STATUS_INITIAL = 0,
  GTK_PRINT_STATUS_PREPARING, 
  GTK_PRINT_STATUS_GENERATING_DATA,
  GTK_PRINT_STATUS_SENDING_DATA,
  GTK_PRINT_STATUS_PENDING,
  GTK_PRINT_STATUS_PENDING_ISSUE,
  GTK_PRINT_STATUS_PRINTING,
  GTK_PRINT_STATUS_FINISHED,
  GTK_PRINT_STATUS_FINISHED_ABORTED,
  
  GTK_PRINT_DUPLEX_SIMPLE = 0,
  GTK_PRINT_DUPLEX_HORIZONTAL,
  GTK_PRINT_DUPLEX_VERTICAL,

  GTK_PRINT_PAGES_ALL = 0,
  GTK_PRINT_PAGES_CURRENT,
  GTK_PRINT_PAGES_RANGES,
  GTK_PRINT_PAGES_SELECTION,
  
  GTK_PRINT_QUALITY_LOW = 0,
  GTK_PRINT_QUALITY_NORMAL,
  GTK_PRINT_QUALITY_HIGH,
  GTK_PRINT_QUALITY_DRAFT,
  
  GTK_NUMBER_UP_LAYOUT_LEFT_TO_RIGHT_TOP_TO_BOTTOM = 0,
  GTK_NUMBER_UP_LAYOUT_LEFT_TO_RIGHT_BOTTOM_TO_TOP,
  GTK_NUMBER_UP_LAYOUT_RIGHT_TO_LEFT_TOP_TOP_BOTTOM,
  GTK_NUMBER_UP_LAYOUT_RIGHT_TO_LEFT_BOTTOM_TO_TOP,
  GTK_NUMBER_UP_LAYOUT_TOP_TO_BOTTOM_LEFT_TO_RIGHT,
  GTK_NUMBER_UP_LAYOUT_TOP_TO_BOTTOM_RIGHT_TO_LEFT,
  GTK_NUMBER_UP_LAYOUT_BOTTOM_TO_TOP_LEFT_TO_RIGHT,
  GTK_NUMBER_UP_LAYOUT_BOTTOM_TO_TOP_RIGHT_TO_LEFT,
  
  GTK_STYLE_PROVIDER_PRIORITY_FALLBACK = 1,
  GTK_STYLE_PROVIDER_PRIORITY_THEME = 200,
  GTK_STYLE_PROVIDER_PRIORITY_SETTINGS = 400,
  GTK_STYLE_PROVIDER_PRIORITY_APPLICATION = 600,
  GTK_STYLE_PROVIDER_PRIORITY_USER = 800,
        
  GTK_UNIT_PIXEL = 0,
  GTK_UNIT_POINTS,
  GTK_UNIT_INCH,
  GTK_UNIT_MM,
  
  GTK_STACK_TRANSITION_TYPE_NONE = 0,
  GTK_STACK_TRANSITION_TYPE_CROSSFADE,
  GTK_STACK_TRANSITION_TYPE_SLIDE_RIGHT,
  GTK_STACK_TRANSITION_TYPE_SLIDE_LEFT,
  GTK_STACK_TRANSITION_TYPE_SLIDE_UP,
  GTK_STACK_TRANSITION_TYPE_SLIDE_DOWN,
  GTK_STACK_TRANSITION_TYPE_SLIDE_LEFT_RIGHT,
  GTK_STACK_TRANSITION_TYPE_SLIDE_UP_DOWN,
  GTK_STACK_TRANSITION_TYPE_OVER_UP, -- GTK3.12 from here down
  GTK_STACK_TRANSITION_TYPE_OVER_DOWN,
  GTK_STACK_TRANSITION_TYPE_OVER_LEFT,
  GTK_STACK_TRANSITION_TYPE_OVER_RIGHT, 
  GTK_STACK_TRANSITION_TYPE_UNDER_UP, 
  GTK_STACK_TRANSITION_TYPE_UNDER_DOWN,
  GTK_STACK_TRANSITION_TYPE_UNDER_LEFT,
  GTK_STACK_TRANSITION_TYPE_UNDER_RIGHT,
  GTK_STACK_TRANSITION_TYPE_OVER_UP_DOWN,
  GTK_STACK_TRANSITION_TYPE_OVER_DOWN_UP, -- GTK3.14 from here down
  GTK_STACK_TRANSITION_TYPE_OVER_LEFT_RIGHT,
  GTK_STACK_TRANSITION_TYPE_OVER_RIGHT_LEFT,
     
  GTK_PLACES_OPEN_NORMAL = 0,
  GTK_PLACES_OPEN_NEW_TAB,
  GTK_PLACES_OPEN_NEW_WINDOW,
  
  GDK_PIXBUF_ROTATE_NONE = 0,
  GDK_PIXBUF_ROTATE_COUNTERCLOCKWISE = 90,
  GDK_PIXBUF_ROTATE_UPSIDEDOWN = 180,
  GDK_PIXBUF_ROTATE_CLOCKWISE = 270,
  
  GDK_INTERP_NEAREST = 0,
  GDK_INTERP_TILES,
  GDK_INTERP_BILINEAR,
  GDK_INTERP_HYPER,
  
  CAIRO_EXTEND_REPEAT = 1,
  
  CAIRO_FILL_RULE_EVEN_ODD = 1,
  CAIRO_FILL_RULE_WINDING = 0,
  
  CAIRO_FONT_SLANT_NORMAL = 0,
  CAIRO_FONT_SLANT_ITALIC,
  CAIRO_FONT_SLANT_OBLIQUE,
  
  CAIRO_FONT_WEIGHT_NORMAL = 0, NORMAL = 0,
  CAIRO_FONT_WEIGHT_BOLD,   BOLD = 1,
  
  CAIRO_FORMAT_INVALID = -1,
  CAIRO_FORMAT_ARGB32 = 0,
  CAIRO_FORMAT_RGB24,
  CAIRO_FORMAT_A8,
  CAIRO_FORMAT_A1,
  CAIRO_FORMAT_RGB16_565,
  
  CAIRO_LINE_CAP_BUTT = 0,
  CAIRO_LINE_CAP_ROUND,
  CAIRO_LINE_CAP_SQUARE,
  
  CAIRO_LINE_JOIN_MITER = 0,
  CAIRO_LINE_JOIN_ROUND,
  CAIRO_LINE_JOIN_BEVEL,
  
  CAIRO_OPERATOR_CLEAR = 0,
  CAIRO_OPERATOR_SOURCE,
  CAIRO_OPERATOR_OVER,
  CAIRO_OPERATOR_IN,
  CAIRO_OPERATOR_OUT,
  CAIRO_OPERATOR_ATOP,
  CAIRO_OPERATOR_DEST,
  CAIRO_OPERATOR_DEST_OVER,
  CAIRO_OPERATOR_DEST_IN,
  CAIRO_OPERATOR_DEST_OUT,
  CAIRO_OPERATOR_DEST_ATOP,
  CAIRO_OPERATOR_XOR,
  CAIRO_OPERATOR_ADD,
  CAIRO_OPERATOR_SATURATE,
  CAIRO_OPERATOR_MULTIPLY,
  CAIRO_OPERATOR_SCREEN,
  CAIRO_OPERATOR_OVERLAY,
  CAIRO_OPERATOR_DARKEN,
  CAIRO_OPERATOR_LIGHTEN,
  CAIRO_OPERATOR_COLOR_DODGE,
  CAIRO_OPERATOR_COLOR_BURN,
  CAIRO_OPERATOR_HARD_LIGHT,
  CAIRO_OPERATOR_SOFT_LIGHT,
  CAIRO_OPERATOR_DIFFERENCE,
  CAIRO_OPERATOR_EXCLUSION,
  CAIRO_OPERATOR_HSL_HUE,
  CAIRO_OPERATOR_HSL_SATURATION,
  CAIRO_OPERATOR_HSL_COLOR,
  CAIRO_OPERATOR_HSL_LUMINOSITY,
  
  CAIRO_PDF_VERSION_1_4 = 0,
  CAIRO_PDF_VERSION_1_5,
  
  CAIRO_SVG_VERSION_1_1 = 0,
  CAIRO_SVG_VERSION_1_2,
  
  CAIRO_SURFACE_TYPE_IMAGE = 0,
  CAIRO_SURFACE_TYPE_PDF,
  CAIRO_SURFACE_TYPE_PS,
  CAIRO_SURFACE_TYPE_XLIB,
  CAIRO_SURFACE_TYPE_XCB,
  CAIRO_SURFACE_TYPE_GLITZ,
  CAIRO_SURFACE_TYPE_QUARTZ,
  CAIRO_SURFACE_TYPE_WIN32,
  CAIRO_SURFACE_TYPE_BEOS,
  CAIRO_SURFACE_TYPE_DIRECTFB,
  CAIRO_SURFACE_TYPE_SVG,
  CAIRO_SURFACE_TYPE_OS2,
  CAIRO_SURFACE_TYPE_WIN32_PRINTING,
  CAIRO_SURFACE_TYPE_QUARTZ_IMAGE,
  CAIRO_SURFACE_TYPE_SCRIPT,
  CAIRO_SURFACE_TYPE_QT,
  CAIRO_SURFACE_TYPE_RECORDING,
  CAIRO_SURFACE_TYPE_VG,
  CAIRO_SURFACE_TYPE_GL,
  CAIRO_SURFACE_TYPE_DRM,
  CAIRO_SURFACE_TYPE_TEE,
  CAIRO_SURFACE_TYPE_XML,
  CAIRO_SURFACE_TYPE_SKIA,
  CAIRO_SURFACE_TYPE_SUBSURFACE,
  
  CAIRO_FONT_TYPE_TOY = 0,
  CAIRO_FONT_TYPE_FT,
  CAIRO_FONT_TYPE_WIN32,
  CAIRO_FONT_TYPE_QUARTZ,
  CAIRO_FONT_TYPE_USER
  
public enum ICON_PIXBUF = 1,
     ICON_DISPLAY_NAME,
     ICON_FILENAME,
     ICON_BASE_SIZE,
     ICON_BASE_SCALE,
     ICON_IS_SYMBOLIC
  
function _(atom x, integer t)
if x = 0 then
	crash("Invalid type - pointer is null!")
end if
init(t) register(x,t)
return x
end function

------------------------------------------------------------------------
-- GTK Widget Types -- used rarely, with caution
------------------------------------------------------------------------
global type Object(atom x)return _(x,GObject)end type
global type Window(atom x)return _(x,GtkWindow)end type
global type Dialog(atom x)return _(x,GtkDialog)end type
global type AboutDialog(atom x)return _(x,GtkAboutDialog)end type
global type Assistant(atom x)return _(x,GtkAssistant)end type
global type Box(atom x)return _(x,GtkBox)end type
global type Grid(atom x)return _(x,GtkGrid)end type
global type Revealer(atom x)return _(x,GtkRevealer)end type
global type ListBox(atom x)return _(x,GtkListBox)end type
global type FlowBox(atom x)return _(x,GtkFlowBox)end type
global type Stack(atom x)return _(x,GtkStack)end type
global type StackSwitcher(atom x)return _(x,GtkStackSwitcher)end type
global type Sidebar(atom x)return _(x,GtkSidebar)end type
global type ActionBar(atom x)return _(x,GtkActionBar)end type
global type HeaderBar(atom x)return _(x,GtkHeaderBar)end type
global type Overlay(atom x)return _(x,GtkOverlay)end type
global type ButtonBox(atom x)return _(x,GtkButtonBox)end type
global type Paned(atom x)return _(x,GtkPaned)end type
global type Layout(atom x)return _(x,GtkLayout)end type
global type Notebook(atom x)return _(x,GtkNotebook)end type
global type Expander(atom x)return _(x,GtkExpander)end type
global type AspectFrame(atom x)return _(x,GtkAspectFrame)end type
global type Label(atom x)return _(x,GtkLabel)end type
global type Image(atom x)return _(x,GtkImage)end type
global type Spinner(atom x)return _(x,GtkSpinner)end type
global type InfoBar(atom x)return _(x,GtkInfoBar)end type
global type ProgressBar(atom x)return _(x,GtkProgressBar)end type
global type LevelBar(atom x)return _(x,GtkLevelBar)end type
global type Statusbar(atom x)return _(x,GtkStatusbar)end type
global type AccelLabel(atom x)return _(x,GtkAccelLabel)end type
global type Button(atom x)return _(x,GtkButton)end type
global type CheckButton(atom x)return _(x,GtkCheckButton)end type
global type RadioButton(atom x)return _(x,GtkRadioButton)end type
global type ToggleButton(atom x)return _(x,GtkToggleButton)end type
global type LinkButton(atom x)return _(x,GtkLinkButton)end type
global type MenuButton(atom x)return _(x,GtkMenuButton)end type
global type Switch(atom x)return _(x,GtkSwitch)end type
global type ScaleButton(atom x)return _(x,GtkScaleButton)end type
global type VolumeButton(atom x)return _(x,GtkVolumeButton)end type
global type LockButton(atom x)return _(x,GtkLockButton)end type
global type Entry(atom x)return _(x,GtkEntry)end type
global type EntryBuffer(atom x)return _(x,GtkEntryBuffer)end type
global type EntryCompletion(atom x)return _(x,GtkEntryCompletion)end type
global type Scale(atom x)return _(x,GtkScale)end type
global type SpinButton(atom x)return _(x,GtkSpinButton)end type
global type SearchEntry(atom x)return _(x,GtkSearchEntry)end type
global type SearchBar(atom x)return _(x,GtkSearchBar)end type
global type Editable(atom x)return _(x,GtkEditable)end type
global type TextMark(atom x)return _(x,GtkTextMark)end type
global type TextBuffer(atom x)return _(x,GtkTextBuffer)end type
global type TextTag(atom x)return _(x,GtkTextTag)end type
global type TextTagTable(atom x)return _(x,GtkTextTagTable)end type
global type TextView(atom x)return _(x,GtkTextView)end type
global type TreeModel(atom x)return _(x,GtkTreeModel)end type
global type TreeModelSort(atom x)return _(x,GtkTreeModelSort)end type
global type TreeSelection(atom x)return _(x,GtkTreeSelection)end type
global type TreeViewColumn(atom x)return _(x,GtkTreeViewColumn)end type
global type TreeView(atom x)return _(x,GtkTreeView)end type
global type IconView(atom x)return _(x,GtkIconView)end type
global type CellRendererText(atom x)return _(x,GtkCellRendererText)end type
global type CellRendererAccel(atom x)return _(x,GtkCellRendererAccel)end type
global type CellRendererCombo(atom x)return _(x,GtkCellRendererCombo)end type
global type CellRendererPixbuf(atom x)return _(x,GtkCellRendererPixbuf)end type
global type CellRendererProgress(atom x)return _(x,GtkCellRendererProgress)end type
global type CellRendererSpin(atom x)return _(x,GtkCellRendererSpin)end type
global type CellRendererToggle(atom x)return _(x,GtkCellRendererToggle)end type
global type CellRendererSpinner(atom x)return _(x,GtkCellRendererSpinner)end type
global type ListStore(atom x)return _(x,GtkListStore)end type
global type TreeStore(atom x)return _(x,GtkTreeStore)end type
global type ComboBox(atom x)return _(x,GtkComboBox)end type
global type ComboBoxText(atom x)return _(x,GtkComboBoxText)end type
global type Menu(atom x)return _(x,GtkMenu)end type
global type MenuBar(atom x)return _(x,GtkMenuBar)end type
global type MenuItem(atom x)return _(x,GtkMenuItem)end type
global type RadioMenuItem(atom x)return _(x,GtkRadioMenuItem)end type
global type CheckMenuItem(atom x)return _(x,GtkCheckMenuItem)end type
global type SeparatorMenuItem(atom x)return _(x,GtkSeparatorMenuItem)end type
global type Toolbar(atom x)return _(x,GtkToolbar)end type
global type ToolItem(atom x)return _(x,GtkToolItem)end type
global type ToolPalette(atom x)return _(x,GtkToolPalette)end type
global type ToolButton(atom x)return _(x,GtkToolButton)end type
global type MenuToolButton(atom x)return _(x,GtkMenuToolButton)end type
global type ToggleToolButton(atom x)return _(x,GtkToggleToolButton)end type
global type RadioToolButton(atom x)return _(x,GtkRadioToolButton)end type
global type Popover(atom x)return _(x,GtkPopover)end type
global type PopoverMenu(atom x)return _(x,GtkPopoverMenu)end type
global type ColorChooser(atom x)return _(x,GtkColorChooser)end type
global type ColorButton(atom x)return _(x,GtkColorButton)end type
global type ColorChooserWidget(atom x)return _(x,GtkColorChooserWidget)end type
global type ColorChooserDialog(atom x)return _(x,GtkColorChooserDialog)end type
global type FileChooser(atom x)return _(x,GtkFileChooser)end type
global type FileChooserButton(atom x)return _(x,GtkFileChooserButton)end type
global type FileChooserDialog(atom x)return _(x,GtkFileChooserDialog)end type
global type FileChooserWidget(atom x)return _(x,GtkFileChooserWidget)end type
global type FileFilter(atom x)return _(x,GtkFileFilter)end type
global type FontChooser(atom x)return _(x,GtkFontChooser)end type
global type FontButton(atom x)return _(x,GtkFontButton)end type
global type FontChooserWidget(atom x)return _(x,GtkFontChooserWidget)end type
global type FontChooserDialog(atom x)return _(x,GtkFontChooserDialog)end type
global type PlacesSidebar(atom x)return _(x,GtkPlacesSidebar)end type
global type Frame(atom x)return _(x,GtkFrame)end type
global type Scrollbar(atom x)return _(x,GtkScrollbar)end type
global type ScrolledWindow(atom x)return _(x,GtkScrolledWindow)end type
global type Adjustment(atom x)return _(x,GtkAdjustment)end type
global type Calendar(atom x)return _(x,GtkCalendar)end type
global type GLArea(atom x)return _(x,GtkGLArea)end type
global type Tooltip(atom x)return _(x,GtkTooltip)end type
global type Viewport(atom x)return _(x,GtkViewport)end type
global type Widget(atom x)return _(x,GtkWidget)end type
global type Container(atom x)return _(x,GtkContainer)end type
global type Bin(atom x)return _(x,GtkBin)end type
global type Range(atom x)return _(x,GtkRange)end type
global type PrintContext(atom x)return _(x,GtkPrintContext)end type
global type ListBoxRow(atom x)return _(x,GtkListBoxRow)end type
global type FontFamily(atom x)return _(x,PangoFontFamily)end type
global type FontDescription(atom x)return _(x,PangoFontDescription)end type
global type AppChooserDialog(atom x)return _(x,GtkAppChooserDialog)end type
global type PaperSize(atom x)return _(x,GtkPaperSize)end type
global type DrawingArea(atom x)return _(x,GtkDrawingArea)end type
global type RecentChooserDialog(atom x)return _(x,GtkRecentChooserDialog)end type
global type RecentChooserWidget(atom x)return _(x,GtkRecentChooserWidget)end type
global type RecentChooser(atom x)return _(x,GtkRecentChooser)end type
global type RecentFilter(atom x)return _(x,GtkRecentFilter)end type
global type RecentChooserMenu(atom x)return _(x,GtkRecentChooserMenu)end type
global type EventBox(atom x)return _(x,GtkEventBox)end type
global type TreeModelFilter(atom x)return _(x,GtkTreeModelFilter)end type
global type Application(atom x)return _(x,GtkApplication)end type
global type ApplicationWindow(atom x)return _(x,GtkApplicationWindow)end type
global type Pixbuf(atom x)return _(x,GdkPixbuf)end type
global type IconTheme(atom x)return _(x,GtkIconTheme)end type   
-------------------------
-- © 2015 by Irv Mullins
-------------------------
