import {
  createRouter,
  createWebHistory
} from 'vue-router';
import {
  isAuthenticated
} from '@/services/http';

const router = createRouter({
  history: createWebHistory(
    import.meta.env.BASE_URL),
  routes: [{
      path: '/login',
      name: 'login',
      component: () => import('../views/LoginView.vue'),
    },
    {
      path: '/forgot-password',
      name: 'forgot-password',
      component: () => import('../views/ForgotPassword.vue'),
    },
    {
      path: '/reset-password',
      name: 'reset-password',
      component: () => import('../views/ResetPassword.vue'),
      props: route => ({
        token: route.query.token
      })
    },
    {
      path: '/accept-invite',
      name: 'accept-invite',
      component: () => import('../views/AcceptInviteView.vue'),
    },
    {
      path: '/register-delegacia',
      name: 'register-delegacia',
      component: () => import('../views/RegisterDelegaciaView.vue'),
    },
    {
      path: '/approve-delegacia',
      name: 'approve-delegacia',
      component: () => import('../views/ApproveDelegaciaView.vue'),
    },
    {
      path: '/reject-delegacia',
      name: 'reject-delegacia',
      component: () => import('../views/ApproveDelegaciaView.vue'),
    },
    {
      path: '/',
      component: () => import('../layouts/DefaultLayout.vue'),
      meta: {
        requiresAuth: true
      },
      children: [{
          path: '', // Rota padrão para /
          redirect: '/map' // redireciona para o mapa
        },
        {
          path: 'map',
          name: 'map',
          component: () => import('../views/MapView.vue'),
        },
        {
          path: 'sos',
          name: 'sos',
          component: () => import('../views/SosView.vue'),
        },
        {
          path: 'sos/:id',
          name: 'sos-map',
          component: () => import('../views/SosDetailsView.vue'),
        },
        {
          path: 'sos/:sosId/tracking',
          name: 'tracking',
          component: () => import('../views/TrackingView.vue'),
        },
        {
          path: 'reports',
          name: 'reports',
          component: () => import('../views/ReportsView.vue'),
        },
        {
          path: 'profile',
          name: 'profile',
          component: () => import('../views/AutoridadeProfileView.vue'),
        },
        {
          path: 'change-password',
          name: 'change-password',
          component: () => import('../views/ChangePasswordView.vue'),
        },
        {
          path: 'dashboard',
          name: 'dashboard',
          component: () => import('../views/DashboardView.vue'),
        },
        {
          path: 'users',
          name: 'users',
          component: () => import('../views/UsersView.vue'),
        },

      ],
    },
  ],
});

// Guard de autenticação
router.beforeEach((to, from, next) => {
  const authenticated = isAuthenticated();
  if (to.matched.some(record => record.meta.requiresAuth)) {
    if (!authenticated) {
      next({
        name: 'login'
      });
    } else {
      next();
    }
  } else if (to.name === 'login' && authenticated) {
    next('/');
  } else {
    next();
  }
});

export default router;
