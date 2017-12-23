using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Mx.BaseService.Interfaces
{
    public interface IRepository<T>
    {
        IQueryable<T> Query(IMxIdentity identity);

        IChangeSet<T> Create { get; }

        IChangeSet<T> Update { get; }

        IChangeSet<T> Delete { get; }

        Task SaveAll(IMxIdentity identity);
    }
}
