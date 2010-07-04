/* taken from
 * http://www.ibm.com/developerworks/linux/library/l-posixcap.html#resources
 * Author: Serge E. Hallyn sergeh@us.ibm.com 
 * 16 Oct 2007
 *
 * Adapted cap_capable signature for use with newer kernels
 * Author: Constanze Hausner
 * 04 Jul 2010
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/kprobes.h>
#include <linux/sched.h>

static const char *probed_func = "cap_capable";

int cr_capable (struct task_struct *tsk, const struct cred *cred, int cap, int audit)
{
	printk(KERN_NOTICE "%s: asking for capability %d for %s\n",
		__FUNCTION__, cap, tsk->comm);
	jprobe_return();
	return 0;
}

static struct jprobe jp = {
	.entry = JPROBE_ENTRY(cr_capable)
};

static int __init kprobe_init(void)
{
	int ret;
	jp.kp.symbol_name = (char *)probed_func;

	if ((ret = register_jprobe(&jp)) < 0) {
		printk("%s: register_jprobe failed, returned %d\n",
			__FUNCTION__, ret);
		return -1;
	}
	return 0;
}

static void __exit kprobe_exit(void)
{
	unregister_jprobe(&jp);
	printk("capable kprobes unregistered\n");
}

module_init(kprobe_init);
module_exit(kprobe_exit);

MODULE_LICENSE("GPL");
