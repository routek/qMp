/*
 * niit.h 
 *
 *
 */

#define NIIT_V6PREFIX_1 0x00000000
#define NIIT_V6PREFIX_2 0x00000000
#define NIIT_V6PREFIX_3 0x0000ffff

/*
 * Macros to help debugging
 */

#undef PDEBUG
#ifdef NIIT_DEBUG
#define PDEBUG(fmt, args...) printk(KERN_DEBUG "niit " fmt, ## args)
#else
#  define PDEBUG(fmt, args...) 
#endif

