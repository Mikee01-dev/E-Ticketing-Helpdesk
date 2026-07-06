-- ============================================
-- E-TICKETING HELPDESK - DATABASE SCHEMA
-- Versi: 2.0.0
-- ============================================

-- ============================================
-- 1. TABEL PROFILES
-- ============================================
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  name TEXT,
  role TEXT DEFAULT 'user',
  avatar_url TEXT,
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 2. TABEL TICKETS
-- ============================================
CREATE TABLE tickets (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  ticket_number TEXT UNIQUE,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'open',
  priority TEXT DEFAULT 'medium',
  category TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  assigned_to UUID REFERENCES auth.users(id),
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 3. TABEL COMMENTS
-- ============================================
CREATE TABLE comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  ticket_id UUID REFERENCES tickets(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  message TEXT NOT NULL,
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 4. TABEL TICKET_LOGS
-- ============================================
CREATE TABLE ticket_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  ticket_id UUID REFERENCES tickets(id) ON DELETE CASCADE NOT NULL,
  status_from TEXT,
  status_to TEXT NOT NULL,
  changed_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  note TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 5. TABEL NOTIFICATIONS
-- ============================================
CREATE TABLE notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  ticket_id UUID REFERENCES tickets(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TRIGGERS & FUNCTIONS
-- ============================================

-- 5.1 Auto generate ticket number (TCK-XXXXX)
CREATE OR REPLACE FUNCTION generate_ticket_number()
RETURNS TRIGGER AS $$
DECLARE
  next_num INTEGER;
BEGIN
  SELECT COALESCE(MAX(CAST(SUBSTRING(ticket_number FROM '-([0-9]+)$') AS INTEGER)), 0) + 1
  INTO next_num
  FROM tickets;
  
  NEW.ticket_number := 'TCK-' || TO_CHAR(next_num, 'FM00000');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_ticket_number
  BEFORE INSERT ON tickets
  FOR EACH ROW
  EXECUTE FUNCTION generate_ticket_number();

-- 5.2 Auto update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_tickets_updated_at
  BEFORE UPDATE ON tickets
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- 5.3 Auto insert log saat status berubah
CREATE OR REPLACE FUNCTION log_ticket_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO ticket_logs (ticket_id, status_from, status_to, changed_by, note)
    VALUES (NEW.id, OLD.status, NEW.status, auth.uid(), 
            'Status updated from ' || COALESCE(OLD.status, 'null') || ' to ' || NEW.status);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ticket_status_log_trigger
  AFTER UPDATE OF status ON tickets
  FOR EACH ROW
  EXECUTE FUNCTION log_ticket_status_change();

-- 5.4 Auto create profile saat register
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, name, role)
  VALUES (
    NEW.id, 
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)), 
    'user'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- 5.5 Validasi tipe image
CREATE OR REPLACE FUNCTION validate_image_type()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.name NOT SIMILAR TO '%.(jpg|jpeg|png|webp|heic)%' THEN
    RAISE EXCEPTION 'Only image files (jpg, jpeg, png, webp) are allowed';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_image_type
  BEFORE INSERT ON storage.objects
  FOR EACH ROW
  WHEN (NEW.bucket_id = 'ticket_images')
  EXECUTE FUNCTION validate_image_type();

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- 6.1 Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- 6.2 PROFILES POLICIES
CREATE POLICY "Users can view all profiles" ON profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- 6.3 TICKETS POLICIES
CREATE POLICY "Users can view own tickets" ON tickets
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all tickets" ON tickets
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'helpdesk')
    )
  );

CREATE POLICY "Users can create tickets" ON tickets
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own tickets" ON tickets
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Admins can update all tickets" ON tickets
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'helpdesk')
    )
  );

-- 6.4 COMMENTS POLICIES
CREATE POLICY "Users can view comments" ON comments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM tickets
      WHERE tickets.id = comments.ticket_id
      AND (tickets.user_id = auth.uid() OR tickets.assigned_to = auth.uid())
    )
  );

CREATE POLICY "Users can create comments" ON comments
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM tickets
      WHERE tickets.id = comments.ticket_id
      AND tickets.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can create comments on all tickets" ON comments
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'helpdesk')
    )
  );

-- 6.5 TICKET_LOGS POLICIES
CREATE POLICY "Users can view own ticket logs" ON ticket_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM tickets
      WHERE tickets.id = ticket_logs.ticket_id
      AND tickets.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can view all ticket logs" ON ticket_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'helpdesk')
    )
  );

CREATE POLICY "Service role can insert logs" ON ticket_logs
  FOR INSERT WITH CHECK (true);

-- 6.6 NOTIFICATIONS POLICIES
CREATE POLICY "Users can view own notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications" ON notifications
  FOR INSERT WITH CHECK (true);

-- ============================================
-- STORAGE BUCKETS
-- ============================================

-- 7.1 Bucket ticket_images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('ticket_images', 'ticket_images', true);

-- 7.2 Bucket avatars
INSERT INTO storage.buckets (id, name, public) 
VALUES ('avatars', 'avatars', true);

-- ============================================
-- STORAGE POLICIES
-- ============================================

-- 8.1 ticket_images policies
CREATE POLICY "Anyone can view ticket_images" ON storage.objects
  FOR SELECT USING (bucket_id = 'ticket_images');

CREATE POLICY "Users can upload ticket_images" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'ticket_images');

-- 8.2 avatars policies
CREATE POLICY "Anyone can view avatars" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload avatars" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'avatars');

CREATE POLICY "Users can update own avatars" ON storage.objects
  FOR UPDATE USING (bucket_id = 'avatars' AND owner = auth.uid());

-- ============================================
-- SAMPLE DATA (Optional)
-- ============================================

-- Insert sample admin user (run after user created)
-- UPDATE profiles SET role = 'admin' WHERE email = 'admin@test.com';

-- ============================================
-- END OF DATABASE SCHEMA
-- ============================================