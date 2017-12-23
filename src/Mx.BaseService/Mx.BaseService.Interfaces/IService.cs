using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Mx.BaseService.Interfaces
{
    public interface IService<TKey, T> : IComponent
    {
        IQueryable<T> Query(IMxIdentity identity);

        Task Create(IMxIdentity identity, T model);

        Task Update(IMxIdentity identity, TKey key, T model);

        Task Delete(IMxIdentity identity, TKey key);

        Task Describe(IMxIdentity identity, TKey key);
    }

    public static class ServiceExtensions
    {

    } 
}
