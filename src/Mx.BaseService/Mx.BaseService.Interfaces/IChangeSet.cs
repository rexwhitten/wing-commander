using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Mx.BaseService.Interfaces
{
    public interface IChangeSet<T>
    {
        IEnumerable<T> Items { get; }

        void Add(T item);

        Task Save(IMxIdentity identity);
    }
}
