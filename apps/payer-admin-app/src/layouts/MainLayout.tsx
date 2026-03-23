import { useState } from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import {
    AppShell,
    Header,
    Sidebar,
    Box,
    Avatar,
    Menu,
    MenuItem,
    Typography,
    Divider,
    ColorSchemeToggle,
} from '@wso2/oxygen-ui';
import {
    FileText,
    ArrowLeftRight,
    ClipboardList,
    Settings,
    User,
    LogOut,
    ChevronDown,
} from '@wso2/oxygen-ui-icons-react';
import { useAuth } from '../components/useAuth';

interface SidebarItem {
    id: string;
    label: string;
    icon: React.ReactNode;
    path?: string;
    expandIcon?: React.ReactNode;
    expanded?: boolean;
    onToggle?: () => void;
    children?: SidebarChildItem[];
}

interface SidebarChildItem {
    id: string;
    label: string;
    icon: React.ReactNode;
    path: string;
}

export default function MainLayout() {
    const navigate = useNavigate();
    const location = useLocation();
    const { userInfo, logout, isLoading } = useAuth();
    const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
    const [manageExpanded, setManageExpanded] = useState(false);
    const [collapsed, setCollapsed] = useState(false);

    const handleMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
        setAnchorEl(event.currentTarget);
    };

    const handleMenuClose = () => {
        setAnchorEl(null);
    };

    const handleLogout = async () => {
        try {
            // Call logout endpoint if it exists
            await fetch("/auth/logout", { method: "POST" });
        } catch (error) {
            console.error("Logout error:", error);
        } finally {
            logout();
            handleMenuClose();
            window.location.href="/auth/login";
        }
    };

    // Get display name and email
    const displayName = userInfo 
        ? `${userInfo.first_name} ${userInfo.last_name}`.trim() || userInfo.username
        : 'Loading...';
    
    const userEmail = userInfo?.username || '';
    
    // Get initials for avatar
    const getInitials = () => {
        if (!userInfo) return '?';
        if (userInfo.first_name && userInfo.last_name) {
            return `${userInfo.first_name[0]}${userInfo.last_name[0]}`.toUpperCase();
        }
        return userInfo.username[0]?.toUpperCase() || '?';
    };

    const sidebarItems: SidebarItem[] = [
        {
            id: 'pa-requests',
            label: 'PA Requests',
            icon: <FileText size={20} />,
            path: '/pa-requests',
        },
        {
            id: 'payer-data-exchange',
            label: 'Payer Data Exchange',
            icon: <ArrowLeftRight size={20} />,
            path: '/payer-data-exchange',
        },
        {
            id: 'questionnaires',
            label: 'Questionnaires',
            icon: <ClipboardList size={20} />,
            path: '/questionnaires',
        },
        {
            id: 'manage',
            label: 'Manage',
            icon: <Settings size={20} />,
            expandIcon: <ChevronDown size={16} />,
            expanded: manageExpanded,
            onToggle: () => setManageExpanded(!manageExpanded),
            children: [
                {
                    id: 'payers',
                    label: 'Payers',
                    icon: <User size={20} />,
                    path: '/manage/payers',
                },
            ],
        },
    ];

    const renderSidebarItem = (item: SidebarItem) => {
        if (item.children) {
            return (
                <Box key={item.id}>
                    <Box
                        onClick={item.onToggle}
                        sx={{
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'space-between',
                            px: 2,
                            py: 1.5,
                            cursor: 'pointer',
                            borderRadius: 1,
                            mx: 1,
                            '&:hover': {
                                bgcolor: 'action.hover',
                            },
                        }}
                    >
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                            {item.icon}
                            {!collapsed && (
                                <Typography variant="body2">{item.label}</Typography>
                            )}
                        </Box>
                        {!collapsed && (
                            <Box
                                sx={{
                                    transform: item.expanded ? 'rotate(180deg)' : 'rotate(0deg)',
                                    transition: 'transform 0.2s',
                                }}
                            >
                                {item.expandIcon}
                            </Box>
                        )}
                    </Box>
                    {item.expanded && !collapsed && (
                        <Box sx={{ pl: 4 }}>
                            {item.children.map((child: SidebarChildItem) => (
                                <Box
                                    key={child.id}
                                    onClick={() => navigate(child.path)}
                                    sx={{
                                        display: 'flex',
                                        alignItems: 'center',
                                        gap: 2,
                                        px: 2,
                                        py: 1.5,
                                        cursor: 'pointer',
                                        borderRadius: 1,
                                        mx: 1,
                                        bgcolor:
                                            location.pathname === child.path
                                                ? 'action.selected'
                                                : 'transparent',
                                        '&:hover': {
                                            bgcolor: 'action.hover',
                                        },
                                    }}
                                >
                                    {child.icon}
                                    <Typography variant="body2">{child.label}</Typography>
                                </Box>
                            ))}
                        </Box>
                    )}
                </Box>
            );
        }

        return (
            <Box
                key={item.id}
                onClick={() => item.path && navigate(item.path)}
                sx={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: 2,
                    px: 2,
                    py: 1.5,
                    cursor: 'pointer',
                    borderRadius: 1,
                    mx: 1,
                    bgcolor:
                        location.pathname === item.path ? 'action.selected' : 'transparent',
                    '&:hover': {
                        bgcolor: 'action.hover',
                    },
                }}
            >
                {item.icon}
                {!collapsed && <Typography variant="body2">{item.label}</Typography>}
            </Box>
        );
    };

    return (
        <AppShell>
            <AppShell.Navbar>
                <Header sx={{ border: 'none' }}>
                    <Header.Toggle
                        collapsed={collapsed}
                        onToggle={() => setCollapsed(!collapsed)}
                    />
                    <Header.Brand>
                        <Header.BrandTitle>WSO2 Payer Admin Portal</Header.BrandTitle>
                    </Header.Brand>
                    <Header.Spacer />
                    <Header.Actions>
                        <ColorSchemeToggle />
                        <Box
                            onClick={handleMenuOpen}
                            sx={{
                                display: 'flex',
                                alignItems: 'center',
                                gap: 1.5,
                                cursor: 'pointer',
                                px: 1.5,
                                py: 0.5,
                                borderRadius: 1,
                                '&:hover': {
                                    bgcolor: 'action.hover',
                                },
                            }}
                        >
                            <Avatar sx={{ width: 32, height: 32, bgcolor: 'primary.main' }}>
                                <Typography variant="h6" sx={{ color: '#fff' }}>
                                    {isLoading ? <User size={20} /> : getInitials()}
                                </Typography>
                            </Avatar>
                            <Typography variant="body2" sx={{ fontWeight: 500 }}>
                                {displayName}
                            </Typography>
                            <ChevronDown size={16} />
                        </Box>
                        <Menu
                            anchorEl={anchorEl}
                            open={Boolean(anchorEl)}
                            onClose={handleMenuClose}
                            anchorOrigin={{
                                vertical: 'bottom',
                                horizontal: 'right',
                            }}
                            transformOrigin={{
                                vertical: 'top',
                                horizontal: 'right',
                            }}
                            slotProps={{
                                paper: {
                                    sx: {
                                        minWidth: 250,
                                        mt: 1,
                                    },
                                },
                            }}
                        >
                            <Box sx={{ px: 2, py: 1.5, display: 'flex', alignItems: 'center', gap: 2 }}>
                                <Avatar sx={{ width: 40, height: 40, bgcolor: 'primary.main' }}>
                                    <Typography variant="h6" sx={{ color: '#fff' }}>
                                        {isLoading ? <User size={20} /> : getInitials()}
                                    </Typography>
                                </Avatar>
                                <Box>
                                    <Typography variant="subtitle2">{displayName}</Typography>
                                    <Typography variant="caption" color="text.secondary">
                                        {userEmail}
                                    </Typography>
                                </Box>
                            </Box>
                            <Divider />
                            <MenuItem onClick={handleLogout}>
                                <LogOut size={16} style={{ marginRight: 8 }} />
                                Logout
                            </MenuItem>
                        </Menu>
                    </Header.Actions>
                </Header>
            </AppShell.Navbar>

            <AppShell.Sidebar>
                <Sidebar collapsed={collapsed} sx={{ width: collapsed ? 64 : '20vw', border: 'none' }}>
                    <Sidebar.Nav>{sidebarItems.map((item) => renderSidebarItem(item))}</Sidebar.Nav>
                </Sidebar>
            </AppShell.Sidebar>

            <AppShell.Main>
                <Box
                    sx={{
                        width: '100%',
                        height: '100%',
                        bgcolor: 'background.default',
                        borderTopLeftRadius: 24,
                        overflow: 'auto',
                    }}
                >
                    <Outlet />
                </Box>
            </AppShell.Main>
        </AppShell>
    );
}

