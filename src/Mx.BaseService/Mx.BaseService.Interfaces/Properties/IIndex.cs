using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Mx.BaseService.Interfaces.Properties
{
    public interface IIndex<T>
    {
        Uri Type(T item);

        Uri Reference(T item);
    }
}
