CREATE INDEX IF NOT EXISTS idx_books_title_lower ON books(LOWER(title));
CREATE INDEX IF NOT EXISTS idx_books_author_lower ON books(LOWER(author));


CREATE INDEX IF NOT EXISTS idx_loans_overdue 
ON loans(due_at, returned_at) 
WHERE returned_at IS NULL;


CREATE INDEX IF NOT EXISTS idx_loans_active 
ON loans(member_id, copy_id) 
WHERE returned_at IS NULL;


CREATE INDEX IF NOT EXISTS idx_fines_created_paid 
ON fines(created_at, paid_at);


CREATE INDEX IF NOT EXISTS idx_fines_pending 
ON fines(loan_id, amount) 
WHERE paid_at IS NULL;


CREATE INDEX IF NOT EXISTS idx_books_category ON books(category);
CREATE INDEX IF NOT EXISTS idx_copies_book_status ON copies(book_id, status);


CREATE INDEX IF NOT EXISTS idx_members_type ON members(member_type);
CREATE INDEX IF NOT EXISTS idx_loans_member_dates ON loans(member_id, loaned_at, returned_at);


ANALYZE members;
ANALYZE books;
ANALYZE copies;
ANALYZE loans;
ANALYZE fines;