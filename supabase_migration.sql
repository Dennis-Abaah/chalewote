-- =====================================================
-- CHALE WOTE: Battle Royale Multiplayer — Supabase Migration
-- Paste this entire script into the Supabase SQL Editor and run.
-- =====================================================

-- 1. Create the ROOMS table
CREATE TABLE IF NOT EXISTS public.rooms (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code        text UNIQUE NOT NULL,
  max_players int  DEFAULT 3 CHECK (max_players IN (2, 3)),
  status      text DEFAULT 'waiting' CHECK (status IN ('waiting', 'playing', 'finished')),
  created_at  timestamptz DEFAULT now()
);

-- 2. Create the ROOM_PLAYERS table
CREATE TABLE IF NOT EXISTS public.room_players (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id     uuid NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
  player_name text NOT NULL,
  slot_index  int  NOT NULL CHECK (slot_index >= 0 AND slot_index <= 2),
  is_alive    boolean DEFAULT true,
  finish_rank int,
  joined_at   timestamptz DEFAULT now(),
  -- Enforce unique player name per room
  UNIQUE (room_id, player_name),
  -- Enforce unique slot per room
  UNIQUE (room_id, slot_index)
);

-- 3. Enable Row Level Security on both tables
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_players ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies: Allow full public (anon) read/write access
-- ROOMS: SELECT
CREATE POLICY "rooms_select_all" ON public.rooms
  FOR SELECT TO anon USING (true);

-- ROOMS: INSERT
CREATE POLICY "rooms_insert_all" ON public.rooms
  FOR INSERT TO anon WITH CHECK (true);

-- ROOMS: UPDATE
CREATE POLICY "rooms_update_all" ON public.rooms
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

-- ROOMS: DELETE
CREATE POLICY "rooms_delete_all" ON public.rooms
  FOR DELETE TO anon USING (true);

-- ROOM_PLAYERS: SELECT
CREATE POLICY "room_players_select_all" ON public.room_players
  FOR SELECT TO anon USING (true);

-- ROOM_PLAYERS: INSERT
CREATE POLICY "room_players_insert_all" ON public.room_players
  FOR INSERT TO anon WITH CHECK (true);

-- ROOM_PLAYERS: UPDATE
CREATE POLICY "room_players_update_all" ON public.room_players
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

-- ROOM_PLAYERS: DELETE
CREATE POLICY "room_players_delete_all" ON public.room_players
  FOR DELETE TO anon USING (true);

-- 5. Enable Supabase Realtime for both tables
-- This adds them to the supabase_realtime publication so clients
-- can subscribe to INSERT/UPDATE/DELETE changes.
ALTER PUBLICATION supabase_realtime ADD TABLE public.rooms;
ALTER PUBLICATION supabase_realtime ADD TABLE public.room_players;

-- 6. (Optional) Create an index on room code for fast lookups
CREATE INDEX IF NOT EXISTS idx_rooms_code ON public.rooms (code);

-- 7. (Optional) Create an index on room_players room_id for fast joins
CREATE INDEX IF NOT EXISTS idx_room_players_room ON public.room_players (room_id);

-- =====================================================
-- DONE. Your tables, policies, and realtime are set up.
-- =====================================================
