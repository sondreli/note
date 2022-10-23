#!
#1. notes should be stored centrally in sqlite
#2. notes should be taggable by adding #my-tag in the file
#3. list functionallity by name and tags
#4. written in perl6?

#first outline
#need dbsetup script
#dbmodel
#note - id, title, text
#tag - id, name, note_id

#should use EDITOR=vi
#this mean that the application will need to open and store files some place.
#store under /tmp/note/{note_id}
#
# New fucntionallity
# - note read   - to read existing files into note
# - note rename - to rename a note

use DBIish;

class Note {
    has Int $.id;
    has Str $.title;
    has Str $.text is rw;
    has Str @.tags;
}

class Database {
    my $databaseFile = "{%*ENV<HOME>}/.config/note/note.db";
    my $dbh = DBIish.connect("SQLite", database => $databaseFile);

    method createNote(Note $note) {
        my $stm = $dbh.prepare(q:to/STATEMENT/);
            INSERT INTO note (title, text)
            VALUES (?, ?)
            STATEMENT
        my $tagStm = $dbh.prepare(q:to/STATEMENT/);
            INSERT INTO tag (name, note_id) VALUES (?, ?)
            STATEMENT

        $stm.execute($note.title, $note.text);
        # TODO: Should maybe get the id in some other way. Preferably .last_row_id but this is note implemented in DBIish.
        my $storedNote = self.getNote($note.title);
        $tagStm.execute($_, $storedNote.id) for $note.tags;
    }

    method dropNote(Int $id) {
        my $stm = $dbh.prepare(q:to/STATEMENT/);
            DELETE FROM note WHERE id = ?
            STATEMENT
        
        $stm.execute($id);
    }

    method getNote(Str $title) {
        my Note $note;

        my $stm = $dbh.prepare(q:to/STATEMENT/);
            SELECT id, title, text FROM note WHERE title = ?
            STATEMENT

        $stm.execute($title);
        my $row = $stm.row();

        return $row 
            ?? Note.new(id => $row[0], title => $row[1], text => $row[2])
            !! Note.new(title => $title, text => "");
    }

    method updateNote(Note $note) {
        my $stm = $dbh.prepare(q:to/STATEMENT/);
            UPDATE note SET title = ?, text = ?
            WHERE id = ?
            STATEMENT
        my $delStm = $dbh.prepare(q:to/STATEMENT/);
            DELETE FROM tag WHERE note_id = ?
            STATEMENT
        my $tagStm = $dbh.prepare(q:to/STATEMENT/);
            INSERT INTO tag (name, note_id) VALUES (?, ?)
            STATEMENT

        $stm.execute($note.title, $note.text, $note.id);
        $delStm.execute($note.id);
        $tagStm.execute($_, $note.id) for $note.tags;
    }

    method persistNote(Note $note) {
        $note.id
            ?? self.updateNote($note)
            !! self.createNote($note);
    }

    method getNotes(Str $query) {
        my $stm = $dbh.prepare(q:to/STATEMENT/);
            SELECT id, title, text FROM note WHERE title LIKE '%' || ? || '%'
            STATEMENT
        my $tagStm = $dbh.prepare(q:to/STATEMENT/);
            SELECT name, note_id FROM tag WHERE note_id = ?
            STATEMENT
             

        $stm.execute($query);

        return $stm.allrows().map: {
            $tagStm.execute($_[0]);
            my @tags = $tagStm.allrows().map: { $_[0] }
            Note.new(id => $_[0], title => $_[1], text => $_[2], tags => @tags);
        }
    }

}

sub findTags(Str $text) {
    my @tags = ($text ~~ m:g/'#' (\w+)/).map: { $_[0].Str };
    return @tags;
}

sub editNote(Str $noteTitle) {
    my $db = Database.new;
    my Note $note = $db.getNote($noteTitle);

    mkdir "/tmp/note" unless "/tmp/note".IO.d;

    my $file = "/tmp/note/{$note.title}";
    spurt $file, $note.text;
    run %*ENV<EDITOR>, $file;
    
    $note.text = $file.IO.slurp;
    if $note.text.chars > 1 {
        $note.tags = findTags($note.text);
        $db.persistNote($note);
    }
}

sub readFile(Str $filename) {
    my $db = Database.new;
    my $text = $filename.IO.slurp;
    my Note $note = Note.new(title => $filename.IO.basename,
                            text => $text,
                            tags => findTags($text));

    $db.persistNote($note);
}

sub renameNote(Str $oldName, Str $newName) {
    # TODO: Implement
}

sub listNotes(Str $query) {
    my $db = Database.new;

    my @notes = $db.getNotes($query);
    say "{$_.title} [{$_.tags}]" for @notes;

    mkdir '/tmp/note' unless '/tmp/note'.IO.d;
    my $fh = open '/tmp/note/completion', :w;
    $fh.say($_.title) for @notes;
    $fh.close;
}

sub dropNote(Str $query) {
    my $db = Database.new;

    my @notes = $db.getNotes($query);
    given @notes.elems {
        when 1 {
            my $answer = prompt "Are you sure you want to delete {@notes[0].title}? [y/N]: ";
            $db.dropNote(@notes[0].id) if $answer eq 'y';
        }
        when * > 1 {
            my $i = 1;
            say "Which note do you want to delete?";
            say "[{$i++}] {$_.title}" for @notes;
            my $answer = prompt ": ";
            $db.dropNote(@notes[{$answer - 1}].id);
        }
        default { say "No note matching that title." }
    }
}

sub MAIN (*@args) {

    given @args.elems {
        when 1 {
            given @args[0] {
                when "list" { listNotes('%') }
                default     { editNote(@args[0]) }
            }
        }
        when 2 {
            given @args[0] {
                when "list" { listNotes(@args[1]) }
                when "drop" { dropNote(@args[1]) }
                when "read" { readFile(@args[1]) }
            }
        }
        when 3 {
            given @args[0] {
                when "rename" { renameNote(@args[1], @args[2]) }
            }
        }
    }
}
