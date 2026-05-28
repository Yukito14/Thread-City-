import express from 'express';
import { PrismaClient } from '@prisma/client';

const router = express.Router();
const prisma = new PrismaClient();

router.get('/', async (req, res) => {
  try {
    const q = String(req.query.q || '').trim();

    if (!q) {
      return res.json({
        users: [],
        posts: [],
        hashtags: [],
      });
    }

    const cleanHashtag = q.replace('#', '').trim();

    const [users, posts, hashtags] = await Promise.all([
      prisma.user.findMany({
        where: {
          status: 'active',
          OR: [
            {
              username: {
                contains: q,
              },
            },
            {
              nickname: {
                contains: q,
              },
            },
            {
              bio: {
                contains: q,
              },
            },
          ],
        },
        select: {
          id: true,
          username: true,
          nickname: true,
          bio: true,
          avatar_url: true,
          is_verified: true,
          created_at: true,
        },
        take: 10,
      }),

      prisma.post.findMany({
        where: {
          deleted_at: null,
          content: {
            contains: q,
          },
        },
        include: {
          user: {
            select: {
              id: true,
              username: true,
              nickname: true,
              avatar_url: true,
              is_verified: true,
            },
          },
          media: true,
          counts: true,
        },
        orderBy: {
          created_at: 'desc',
        },
        take: 20,
      }),

      prisma.hashtag.findMany({
        where: {
          tag_name: {
            contains: cleanHashtag,
          },
        },
        select: {
          id: true,
          tag_name: true,
          created_at: true,
        },
        take: 10,
      }),
    ]);

    return res.json({
      users,
      posts,
      hashtags,
    });
  } catch (error) {
    console.error('Search error:', error);

    return res.status(500).json({
      message: 'Không thể tìm kiếm',
      error: error.message,
    });
  }
});

export default router;