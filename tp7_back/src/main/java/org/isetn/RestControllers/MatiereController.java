package org.isetn.RestControllers;

import java.util.List;
import org.isetn.entities.Matiere;
import org.isetn.repository.MatiereRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/matieres")
public class MatiereController {

    @Autowired
    private MatiereRepository matiereRepository;

    @GetMapping
    public List<Matiere> getAll() {
        return matiereRepository.findAll();
    }

    @PostMapping
    public Matiere add(@RequestBody Matiere m) {
        return matiereRepository.save(m);
    }
}
