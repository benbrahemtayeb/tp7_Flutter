package org.isetn.repository;

import java.util.List;
import org.isetn.entities.Note;
import org.springframework.data.jpa.repository.JpaRepository;

public interface NoteRepository extends JpaRepository<Note, Integer> {
    List<Note> findByEtudiantId(Integer id);
    List<Note> findByEtudiantClasseCodClass(Integer codClass);
}