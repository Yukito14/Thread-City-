import express from 'express';
import { PrismaClient, NotificationType } from '@prisma/client';

const router = express.Router();
const prisma = new PrismaClient();

const validTypes: NotificationType[] = [
  'like',
  'reply',
  'follow',
  'repost',
  'mention',
];

router.get('/', async (req, res) => {
  try {
    const firebaseUid = String(req.query.firebase_uid || '').trim();
    const type = String(req.query.type || '').trim();

    if (!firebaseUid) {
      return res.status(400).json({
        error: 'Thiếu firebase_uid',
      });
    }

    const currentUser = await prisma.user.findUnique({
      where: {
        firebase_uid: firebaseUid,
      },
      select: {
        id: true,
      },
    });

    if (!currentUser) {
      return res.status(404).json({
        error: 'Không tìm thấy người dùng',
      });
    }

    const whereCondition: any = {
      user_id: currentUser.id,
    };

    if (type && type !== 'all' && validTypes.includes(type as NotificationType)) {
      whereCondition.type = type as NotificationType;
    }

    const notifications = await prisma.notification.findMany({
      where: whereCondition,
      include: {
        actor: {
          select: {
            id: true,
            username: true,
            nickname: true,
            avatar_url: true,
            is_verified: true,
          },
        },
        post: {
          select: {
            id: true,
            content: true,
          },
        },
      },
      orderBy: {
        created_at: 'desc',
      },
      take: 50,
    });

    return res.json(notifications);
  } catch (error: any) {
    console.error('Get notifications error:', error);

    return res.status(500).json({
      error: 'Không thể tải thông báo',
      detail: error.message,
    });
  }
});

router.patch('/read-all', async (req, res) => {
  try {
    const { firebase_uid } = req.body;

    if (!firebase_uid) {
      return res.status(400).json({
        error: 'Thiếu firebase_uid',
      });
    }

    const currentUser = await prisma.user.findUnique({
      where: {
        firebase_uid,
      },
      select: {
        id: true,
      },
    });

    if (!currentUser) {
      return res.status(404).json({
        error: 'Không tìm thấy người dùng',
      });
    }

    await prisma.notification.updateMany({
      where: {
        user_id: currentUser.id,
        is_read: false,
      },
      data: {
        is_read: true,
      },
    });

    return res.json({
      message: 'Đã đánh dấu tất cả thông báo là đã đọc',
    });
  } catch (error: any) {
    console.error('Mark all notifications read error:', error);

    return res.status(500).json({
      error: 'Không thể cập nhật thông báo',
      detail: error.message,
    });
  }
});

router.patch('/:id/read', async (req, res) => {
  try {
    const id = Number(req.params.id);
    const { firebase_uid } = req.body;

    if (!firebase_uid) {
      return res.status(400).json({
        error: 'Thiếu firebase_uid',
      });
    }

    const currentUser = await prisma.user.findUnique({
      where: {
        firebase_uid,
      },
      select: {
        id: true,
      },
    });

    if (!currentUser) {
      return res.status(404).json({
        error: 'Không tìm thấy người dùng',
      });
    }

    await prisma.notification.updateMany({
      where: {
        id,
        user_id: currentUser.id,
      },
      data: {
        is_read: true,
      },
    });

    return res.json({
      message: 'Đã đọc thông báo',
    });
  } catch (error: any) {
    console.error('Mark notification read error:', error);

    return res.status(500).json({
      error: 'Không thể cập nhật thông báo',
      detail: error.message,
    });
  }
});

// Route test để tạo thông báo thử
router.post('/test', async (req, res) => {
  try {
    const {
      recipient_firebase_uid,
      actor_firebase_uid,
      post_id,
      type,
    } = req.body;

    if (!recipient_firebase_uid || !actor_firebase_uid || !type) {
      return res.status(400).json({
        error: 'Thiếu recipient_firebase_uid, actor_firebase_uid hoặc type',
      });
    }

    if (!validTypes.includes(type)) {
      return res.status(400).json({
        error: 'Loại thông báo không hợp lệ',
      });
    }

    const recipient = await prisma.user.findUnique({
      where: {
        firebase_uid: recipient_firebase_uid,
      },
      select: {
        id: true,
      },
    });

    const actor = await prisma.user.findUnique({
      where: {
        firebase_uid: actor_firebase_uid,
      },
      select: {
        id: true,
      },
    });

    if (!recipient || !actor) {
      return res.status(404).json({
        error: 'Không tìm thấy người nhận hoặc người gửi hành động',
      });
    }

    if (recipient.id === actor.id) {
      return res.status(400).json({
        error: 'Không thể tự gửi thông báo cho chính mình',
      });
    }

    const notification = await prisma.notification.create({
      data: {
        user_id: recipient.id,
        actor_id: actor.id,
        post_id: post_id ?? null,
        type,
      },
    });

    return res.status(201).json(notification);
  } catch (error: any) {
    console.error('Create test notification error:', error);

    return res.status(500).json({
      error: 'Không thể tạo thông báo test',
      detail: error.message,
    });
  }
});

export default router;