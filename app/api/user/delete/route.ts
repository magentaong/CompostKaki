import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import { requireUser } from '@/lib/requireUser';

// Ensure this route is not cached and uses Node.js runtime
export const dynamic = 'force-dynamic';
export const runtime = 'nodejs';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL as string;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY as string;

// Support both DELETE and POST methods for account deletion
export async function DELETE(req: NextRequest) {
  return handleDeleteAccount(req);
}

export async function POST(req: NextRequest) {
  return handleDeleteAccount(req);
}

async function handleDeleteAccount(req: NextRequest) {
  const user = await requireUser(req);
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  if (!supabaseServiceRoleKey) {
    return NextResponse.json(
      { error: 'Server configuration error: Service role key not found' },
      { status: 500 }
    );
  }

  // Use service role client for admin operations
  const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey);

  try {
    // Get all bins owned by the user
    const { data: ownedBins } = await supabaseAdmin
      .from('bins')
      .select('id')
      .eq('user_id', user.id);

    const binIds = ownedBins?.map((bin) => bin.id) || [];

    // Delete related data for owned bins
    if (binIds.length > 0) {
      // Delete bin members
      await supabaseAdmin.from('bin_members').delete().in('bin_id', binIds);
      // Delete bin logs
      await supabaseAdmin.from('bin_logs').delete().in('bin_id', binIds);
      // Delete bin messages
      await supabaseAdmin.from('bin_messages').delete().in('bin_id', binIds);
      // Delete bin requests
      await supabaseAdmin.from('bin_requests').delete().in('bin_id', binIds);
      // Delete tasks
      await supabaseAdmin.from('tasks').delete().in('bin_id', binIds);
      // Delete bins
      await supabaseAdmin.from('bins').delete().in('id', binIds);
    }

    // Delete user's membership in other bins
    await supabaseAdmin.from('bin_members').delete().eq('user_id', user.id);

    // Delete user's bin requests
    await supabaseAdmin.from('bin_requests').delete().eq('user_id', user.id);

    // Delete user's tasks (where they are the creator or acceptor)
    await supabaseAdmin.from('tasks').delete().eq('user_id', user.id);
    await supabaseAdmin.from('tasks').update({ accepted_by: null }).eq('accepted_by', user.id);

    // Anonymize user's messages instead of deleting them
    // Keep sender_id and receiver_id (they may be foreign keys), but anonymize the message content
    // The frontend will show "Deleted User" when the profile doesn't exist
    await supabaseAdmin
      .from('bin_messages')
      .update({ 
        message: '[Message from deleted user]'
      })
      .eq('sender_id', user.id);

    // Delete user's notifications (ignore errors if table doesn't exist)
    try {
      await supabaseAdmin.from('user_notifications').delete().eq('user_id', user.id);
    } catch (e) {
      console.warn('Error deleting user_notifications:', e);
    }
    
    // Delete user's FCM tokens (ignore errors if table doesn't exist)
    try {
      await supabaseAdmin.from('user_fcm_tokens').delete().eq('user_id', user.id);
    } catch (e) {
      console.warn('Error deleting user_fcm_tokens:', e);
    }
    
    // Delete user's notification preferences (ignore errors if table doesn't exist)
    try {
      await supabaseAdmin.from('notification_preferences').delete().eq('user_id', user.id);
    } catch (e) {
      console.warn('Error deleting notification_preferences:', e);
    }
    
    // Delete user's bin stats (ignore errors if table doesn't exist)
    try {
      await supabaseAdmin.from('user_bin_stats').delete().eq('user_id', user.id);
    } catch (e) {
      console.warn('Error deleting user_bin_stats:', e);
    }
    
    // Delete user's XP logs (ignore errors if table doesn't exist)
    try {
      await supabaseAdmin.from('xp_logs').delete().eq('user_id', user.id);
    } catch (e) {
      console.warn('Error deleting xp_logs:', e);
    }
    
    // Delete user's badges (ignore errors if table doesn't exist)
    try {
      await supabaseAdmin.from('user_badges').delete().eq('user_id', user.id);
    } catch (e) {
      console.warn('Error deleting user_badges:', e);
    }

    // Delete user's profile (must be done before auth user deletion)
    await supabaseAdmin.from('profiles').delete().eq('id', user.id);

    // Delete the auth user (requires admin privileges)
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(user.id);

    if (deleteError) {
      return NextResponse.json(
        { error: `Failed to delete user account: ${deleteError.message}` },
        { status: 500 }
      );
    }

    return NextResponse.json({ success: true });
  } catch (error: any) {
    console.error('Error deleting user account:', error);
    const errorMessage = error.message || error.toString() || 'Failed to delete account';
    return NextResponse.json(
      { error: `Database error deleting user: ${errorMessage}` },
      { status: 500 }
    );
  }
}

