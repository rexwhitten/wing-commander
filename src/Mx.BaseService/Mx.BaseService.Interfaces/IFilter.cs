using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Mx.BaseService.Interfaces
{
    public interface IFilter<T>
    {
        IQueryable<T> Filter();
    }
}
