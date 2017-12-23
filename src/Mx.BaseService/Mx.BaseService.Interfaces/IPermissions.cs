using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Security;
using System.Security.Claims;
using System.Security.AccessControl;
using System.Security.Permissions;

namespace Mx.BaseService.Interfaces
{
    public interface IPermissions<T> : IComponent
    {
        bool CanCreate(IMxIdentity identity, T item);
        bool CanUpdate(IMxIdentity identity, T item);
        bool CanDelete(IMxIdentity identity, T item);
        IQueryable<T> Filter(IMxIdentity identity, IQueryable<T> query);
    }
    
    public static class IPermissionsExtensions
    {
        public static void Check()
        {
           
        }
    }
}
