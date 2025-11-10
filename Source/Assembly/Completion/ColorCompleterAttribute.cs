using System.Management.Automation;
using PoshCode.Pansies.Palettes;

namespace PoshCode.Pansies.Completion
{
    public class ColorCompleterAttribute : ArgumentCompleterAttribute, IArgumentCompleterFactory
    {
        public ColorCompleterAttribute() { }

        public IArgumentCompleter Create()
        {
            return new X11Palette();
        }
    }
}
